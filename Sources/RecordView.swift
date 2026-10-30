import SwiftUI

struct Bars: View {
    let levels: [Float]
    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, v in
                Capsule().fill(Brand.pink).frame(width: 3, height: 4 + CGFloat(v) * 26)
            }
        }
        .frame(height: 34)
    }
}

struct RecordView: View {
    @StateObject private var rec = Recorder()
    @Environment(\.dismiss) private var dismiss
    @State private var started = false
    @State private var showNotes = false
    @State private var showBanner = true

    var body: some View {
        VStack(spacing: 0) {
            transcriptArea
            if showBanner && rec.isRecording { banner }
            if let m = rec.message {
                Text(m).font(.footnote).foregroundStyle(Brand.danger)
                    .padding(.horizontal, 20).padding(.bottom, 6)
            }
            waveformRow
            controls
        }
        .background(Brand.bg.ignoresSafeArea())
        .navigationTitle(rec.saved ? "Saved" : "New recording")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if !started { started = true; rec.start() } }
        .onDisappear { if rec.isRecording { rec.stop() } }
        .sheet(isPresented: $showNotes) {
            NavigationStack {
                TextEditor(text: $rec.notes)
                    .padding().scrollContentBackground(.hidden).background(Brand.bg)
                    .navigationTitle("Your notes")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showNotes = false } } }
            }
        }
    }

    private var transcriptArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if rec.lines.isEmpty && rec.partial.isEmpty {
                        Text(rec.isRecording ? "Listening… the transcript appears here as people speak."
                                             : "Starting…")
                            .foregroundStyle(Brand.dim)
                    }
                    ForEach(rec.lines) { l in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(timeString(l.time, short: true)).font(.footnote).foregroundStyle(Brand.dim)
                            Text(l.text).font(.system(size: 18)).foregroundStyle(Brand.ink)
                        }
                    }
                    if !rec.partial.isEmpty {
                        Text(rec.partial).font(.system(size: 18)).foregroundStyle(Brand.ink.opacity(0.6))
                    }
                    Color.clear.frame(height: 1).id("end")
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: rec.partial) { _, _ in proxy.scrollTo("end") }
            .onChange(of: rec.lines.count) { _, _ in proxy.scrollTo("end") }
        }
    }

    private var banner: some View {
        HStack {
            Text("Always get permission before recording").font(.subheadline).foregroundStyle(Brand.ink)
            Spacer()
            Button { showBanner = false } label: { Image(systemName: "xmark").foregroundStyle(Brand.dim) }
        }
        .padding(12)
        .background(Brand.panel2, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16).padding(.bottom, 8)
    }

    private var waveformRow: some View {
        HStack(spacing: 10) {
            Bars(levels: Array(rec.levels.prefix(12)))
            HStack(spacing: 6) {
                if rec.isRecording && !rec.isPaused { Circle().fill(Brand.danger).frame(width: 9, height: 9) }
                Text(timeString(rec.elapsed, short: false)).font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundStyle(Brand.ink)
            }
            Bars(levels: Array(rec.levels.suffix(12)))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    @ViewBuilder private var controls: some View {
        if rec.saved {
            Button { dismiss() } label: {
                Text("DONE").font(Brand.display(26)).tracking(1.5).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Brand.gradient, in: Capsule())
            }
            .padding(.horizontal, 24).padding(.vertical, 14)
        } else {
            HStack {
                roundButton("bookmark", rec.isRecording ? Brand.ink : Brand.dim) { rec.addBookmark() }
                Spacer()
                roundButton(rec.isPaused ? "play.fill" : "pause.fill", Brand.ink) { rec.togglePause() }
                Spacer()
                Button { rec.stop() } label: {
                    Image(systemName: "stop.fill").font(.system(size: 28)).foregroundStyle(Brand.danger)
                        .frame(width: 74, height: 74)
                        .background(Brand.danger.opacity(0.18), in: Circle())
                }
                Spacer()
                roundButton("square.and.pencil", Brand.ink) { showNotes = true }
            }
            .padding(.horizontal, 24).padding(.vertical, 14)
        }
    }

    private func roundButton(_ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(color)
                .frame(width: 58, height: 58).background(Brand.panel2, in: Circle())
        }
    }

    private func timeString(_ t: TimeInterval, short: Bool) -> String {
        let s = Int(t)
        if short && s < 3600 { return String(format: "%d:%02d", s / 60, s % 60) }
        return String(format: "%d:%02d:%02d", s / 3600, (s / 60) % 60, s % 60)
    }
}
