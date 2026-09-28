import SwiftUI
import SolKit

@main
struct SolApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            DictateView().tabItem { Label("Dictate", systemImage: "mic.fill") }
            SetupView().tabItem { Label("Setup", systemImage: "gearshape") }
        }
        .tint(Color(red: 0.96, green: 0.70, blue: 0.12)) // Sol amber
    }
}

/// Standalone dictate-and-copy — works without the keyboard, and proves the proxy end to end.
struct DictateView: View {
    @State private var recorder = AudioRecorder()
    @State private var isRecording = false
    @State private var text = ""
    @State private var status = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ScrollView {
                    Text(text.isEmpty ? "Your dictation appears here." : text)
                        .foregroundStyle(text.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))

                if !text.isEmpty {
                    Button {
                        UIPasteboard.general.string = text
                        status = "Copied"
                    } label: { Label("Copy", systemImage: "doc.on.doc") }
                }

                Button(action: toggle) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(isRecording ? .red : Color(red: 0.96, green: 0.70, blue: 0.12))
                }
                Text(status).font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Sol")
        }
    }

    private func toggle() {
        if isRecording { Task { await finish() } } else { begin() }
    }

    private func begin() {
        do { try recorder.start(); isRecording = true; status = "Listening…" }
        catch { status = "Mic error: \(error.localizedDescription)" }
    }

    private func finish() async {
        isRecording = false
        status = "Transcribing…"
        let wav = recorder.stop()
        do {
            let result = try await ProxyClient(config: .load()).transcribe(wav: wav)
            text = result.text
            status = result.cleaned ? "Cleaned (English)" : "Done"
        } catch {
            status = "Failed: \(error.localizedDescription)"
        }
    }
}
