"""Checks the Conversation AI build state in App Store Connect and makes sure an internal TestFlight group exists.
Runs in GitHub Actions using repository secrets. Prints no personal data (this repo is public)."""
import os, time, json, urllib.request, urllib.error
import jwt

KEY, KID, ISS, BID = (os.environ[k] for k in ("ASC_KEY_P8", "ASC_KEY_ID", "ASC_ISSUER_ID", "BUNDLE_ID"))

def token():
    now = int(time.time())
    return jwt.encode({"iss": ISS, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
                      KEY, algorithm="ES256", headers={"kid": KID, "typ": "JWT"})

def call(method, path, body=None):
    req = urllib.request.Request("https://api.appstoreconnect.apple.com" + path, method=method,
                                 data=json.dumps(body).encode() if body else None,
                                 headers={"Authorization": "Bearer " + token(), "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        return {"error": e.code, "detail": e.read().decode()[:300]}

def note(msg): print(f"::notice::{msg}")

apps = call("GET", f"/v1/apps?filter[bundleId]={BID}")
if "error" in apps or not apps.get("data"):
    note(f"App lookup failed: {str(apps)[:300]}"); raise SystemExit(1)
app_id = apps["data"][0]["id"]
note("App record found")

builds = call("GET", f"/v1/builds?filter[app]={app_id}&limit=5&sort=-uploadedDate")
if "error" in builds: note(f"Builds error: {builds['error']} {builds['detail']}")
else:
    items = builds.get("data", [])
    note(f"Builds found: {len(items)}")
    for b in items:
        a = b["attributes"]
        note(f"build {a.get('version')} state={a.get('processingState')} expired={a.get('expired')} uploaded={a.get('uploadedDate')}")

groups = call("GET", f"/v1/apps/{app_id}/betaGroups")
gl = groups.get("data", []) if "error" not in groups else []
internal = [g for g in gl if g["attributes"].get("isInternalGroup")]
note(f"Beta groups: {len(gl)} (internal: {len(internal)})")
if not internal:
    r = call("POST", "/v1/betaGroups", {"data": {"type": "betaGroups",
        "attributes": {"name": "Internal", "isInternalGroup": True, "hasAccessToAllBuilds": True},
        "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})
    if "error" in r: note(f"Create group error: {r['error']} {r['detail']}"); raise SystemExit(1)
    internal = [r["data"]]; note("Created internal group 'Internal' with access to all builds")
gid = internal[0]["id"]

users = call("GET", "/v1/users?limit=50")
added = 0
for u in users.get("data", []):
    a = u["attributes"]
    if not ({"ACCOUNT_HOLDER", "ADMIN"} & set(a.get("roles", []))): continue
    r = call("POST", "/v1/betaTesters", {"data": {"type": "betaTesters",
        "attributes": {"email": a["username"], "firstName": a.get("firstName") or "Tom", "lastName": a.get("lastName") or "B"},
        "relationships": {"betaGroups": {"data": [{"type": "betaGroups", "id": gid}]}}}})
    if "error" in r: note(f"Add tester result: {r['error']} (409 usually means already added)")
    else: added += 1
note(f"Testers added to internal group: {added}")
