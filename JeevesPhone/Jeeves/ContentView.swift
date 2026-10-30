import SwiftUI

struct ContentView: View {
    @StateObject private var voice = Voice(); @StateObject private var brain = Brain()
    @State private var reply = "Tap the button and speak."
    @State private var busy = false
    private let pink = Color(red: 1, green: 0.604, blue: 0.965)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 28) {
                Text("J.E.E.V.E.S.").font(.custom("BebasNeue-Regular", size: 40, relativeTo: .largeTitle)).foregroundStyle(pink).padding(.top, 24)
                Spacer()
                Text(voice.heard.isEmpty ? " " : "“\(voice.heard)”").foregroundStyle(.gray).multilineTextAlignment(.center).padding(.horizontal)
                Text(reply).font(.title3).foregroundStyle(.white).multilineTextAlignment(.center).padding(.horizontal)
                Spacer()
                Button { tap() } label: {
                    Circle().stroke(pink, lineWidth: 4).background(Circle().fill(voice.listening ? pink : .clear))
                        .frame(width: 120, height: 120).overlay(Image(systemName: voice.listening ? "stop.fill" : "mic.fill").font(.largeTitle).foregroundStyle(voice.listening ? .black : pink))
                        .scaleEffect(voice.speaking || busy ? 1.08 : 1).animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: voice.speaking || busy)
                }.padding(.bottom, 48)
            }
        }
        .task {
            await voice.authorise()
            voice.onFinal = { text in Task { await respond(text) } }
        }
    }

    func tap() { if voice.listening { voice.stop() } else if voice.speaking { voice.stopSpeaking() } else { voice.start() } }

    func respond(_ text: String) async {
        busy = true; let r = await brain.ask(text); busy = false
        reply = r; voice.speak(r)
    }
}
