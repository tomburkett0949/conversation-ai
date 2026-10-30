import SwiftUI

enum Feature: String, CaseIterable, Identifiable {
    case record = "Record", importAudio = "Import", meetings = "Meetings"
    case askAI = "Ask AI", actions = "Actions", search = "Search"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .record: return "mic.fill"
        case .importAudio: return "square.and.arrow.down"
        case .meetings: return "list.bullet.rectangle"
        case .askAI: return "sparkles"
        case .actions: return "checkmark.circle"
        case .search: return "magnifyingglass"
        }
    }
    var subtitle: String {
        switch self {
        case .record: return "Start a new recording"
        case .importAudio: return "Audio or video file"
        case .meetings: return "Your recordings"
        case .askAI: return "Ask across everything"
        case .actions: return "What needs doing"
        case .search: return "Find any moment"
        }
    }
}

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = "system"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

struct HomeView: View {
    @State private var showSettings = false
    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Brand.productName.uppercased())
                        .font(Brand.display(44)).tracking(2).foregroundStyle(Brand.ink)
                    Text(Brand.tagline).foregroundStyle(Brand.dim)
                }
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Feature.allCases.filter { $0 != .record }) { f in
                        NavigationLink(value: f) { tile(f) }.buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(Brand.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { bottomBar }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .navigationDestination(for: Feature.self) { f in
            switch f {
            case .record: RecordView()
            case .meetings: MeetingsView()
            case .askAI: AskView()
            case .importAudio: ImportView()
            case .actions: ActionsView()
            default: ComingSoonView(title: f.rawValue)
            }
        }
    }

    private var bottomBar: some View {
        HStack(alignment: .bottom) {
            barItem("house.fill", "Home", active: true)
            NavigationLink(value: Feature.meetings) { barItem("list.bullet.rectangle", "Meetings") }
            NavigationLink(value: Feature.record) {
                Image(systemName: "mic.fill").font(.system(size: 28)).foregroundStyle(.white)
                    .frame(width: 66, height: 66).background(Brand.gradient, in: Circle())
                    .shadow(color: Brand.hot.opacity(0.4), radius: 8, y: 3)
                    .offset(y: -10)
            }
            NavigationLink(value: Feature.askAI) { barItem("sparkles", "Ask AI") }
            Button { showSettings = true } label: { barItem("gearshape", "Settings") }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8).padding(.top, 8).padding(.bottom, 4)
        .background(Brand.panel.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Brand.line).frame(height: 1) }
    }

    private func barItem(_ icon: String, _ title: String, active: Bool = false) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 20))
            Text(title).font(.caption2)
        }
        .foregroundStyle(active ? Brand.pink : Brand.dim)
        .frame(maxWidth: .infinity)
    }

    private func tile(_ f: Feature) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: f.icon).font(.system(size: 24)).foregroundStyle(Brand.pink)
            Text(f.rawValue.uppercased()).font(Brand.display(26)).tracking(1).foregroundStyle(Brand.ink)
            Text(f.subtitle).font(.footnote).foregroundStyle(Brand.dim)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(16)
        .background(Brand.panel, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.line, lineWidth: 1))
    }
}

struct ComingSoonView: View {
    let title: String
    var body: some View {
        VStack(spacing: 12) {
            Text(title.uppercased()).font(Brand.display(40)).foregroundStyle(Brand.ink)
            Text("Coming in a later build.").foregroundStyle(Brand.dim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.bg.ignoresSafeArea())
    }
}
