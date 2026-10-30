import SwiftUI

struct RecordView: View {
    @StateObject private var rec = Recorder()
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            if rec.isRecording {
                HStack(spacing: 8) {
                    Circle().fill(Brand.danger).frame(width: 12, height: 12)
                        .opacity(pulse ? 0.25 : 1)
                    Text("RECORDING").font(Brand.display(24)).tracking(2).foregroundStyle(Brand.danger)
                }
                .onAppear { withAnimation(.easeInOut(duration: 0.8).repeatForever()) { pulse = true } }
            }
            Text(timeString(rec.elapsed))
                .font(.system(size: 64, weight: .light, design: .monospaced)).foregroundStyle(Brand.ink)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Brand.panel2)
                    Capsule().fill(Brand.gradient).frame(width: geo.size.width * CGFloat(rec.level))
                }
            }
            .frame(height: 8).padding(.horizontal, 40)

            Button { rec.isRecording ? rec.stop() : rec.start() } label: {
                ZStack {
                    Circle().stroke(Brand.line, lineWidth: 4).frame(width: 96, height: 96)
                    RoundedRectangle(cornerRadius: rec.isRecording ? 8 : 34)
                        .fill(rec.isRecording ? Brand.danger : Brand.hot)
                        .frame(width: rec.isRecording ? 36 : 68, height: rec.isRecording ? 36 : 68)
                }
            }
            .buttonStyle(.plain)

            Text("Tell everyone in the conversation that you are recording.")
                .font(.footnote).foregroundStyle(Brand.dim).multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            if let m = rec.message { Text(m).font(.footnote).foregroundStyle(Brand.danger).padding(.horizontal, 30) }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.bg.ignoresSafeArea())
        .navigationTitle("Record")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { if rec.isRecording { rec.stop() } }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d:%02d", s / 3600, (s / 60) % 60, s % 60)
    }
}
