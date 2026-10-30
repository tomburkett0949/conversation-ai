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

struct HomeView: View {
    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Brand.productName.uppercased())
                        .font(Brand.display(44)).tracking(2).foregroundStyle(Brand.ink)
                    Text(Brand.tagline).foregroundStyle(Brand.dim)
                }
                NavigationLink(value: Feature.record) { bigRecordButton }
                    .buttonStyle(.plain)
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
        .navigationDestination(for: Feature.self) { f in
            switch f {
            case .record: RecordView()
            case .meetings: MeetingsView()
            default: ComingSoonView(title: f.rawValue)
            }
        }
    }

    private var bigRecordButton: some View {
        HStack(spacing: 14) {
            Image(systemName: "mic.fill").font(.system(size: 30))
            VStack(alignment: .leading) {
                Text("RECORD").font(Brand.display(34)).tracking(1.5)
                Text("Tap to start a meeting or lecture").font(.subheadline).opacity(0.85)
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(22)
        .background(Brand.gradient, in: RoundedRectangle(cornerRadius: 16))
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
