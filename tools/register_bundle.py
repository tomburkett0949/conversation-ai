"""Registers a bundle ID with Apple (needed before the app record can be created). Uses repository secrets; prints no personal data."""
import os, time, json, urllib.request, urllib.error
import jwt
KEY, KID, ISS, BID = (os.environ[k] for k in ("ASC_KEY_P8", "ASC_KEY_ID", "ASC_ISSUER_ID", "BUNDLE_ID"))
def call(method, path, body=None):
    now = int(time.time())
    tok = jwt.encode({"iss": ISS, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"}, KEY, algorithm="ES256", headers={"kid": KID, "typ": "JWT"})
    req = urllib.request.Request("https://api.appstoreconnect.apple.com" + path, method=method, data=json.dumps(body).encode() if body else None,
                                 headers={"Authorization": "Bearer " + tok, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r: return json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e: return {"error": e.code, "detail": e.read().decode()[:400]}
r = call("GET", f"/v1/bundleIds?filter[identifier]={BID}")
if r.get("data"): print("::notice::Bundle ID already registered"); raise SystemExit(0)
r = call("POST", "/v1/bundleIds", {"data": {"type": "bundleIds", "attributes": {"identifier": BID, "name": "Jeeves", "platform": "IOS"}}})
if "error" in r: print(f"::error::Register failed {r['error']} {r['detail']}"); raise SystemExit(1)
print("::notice::Bundle ID registered")
