import SwiftUI
import SolKit

/// Onboarding + settings: enter the proxy URL + account token, pick a language, request mic access,
/// and walk the user through enabling the Sol Keyboard with Full Access.
struct SetupView: View {
    @State private var proxyURL = SolConfig.load().proxyURL.absoluteString
    @State private var token = SolConfig.load().token
    @State private var language = SolConfig.load().language
    @State private var micGranted = false

    private let languages = ["multi", "ta", "hi", "te", "kn", "ml", "en"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Proxy URL", text: $proxyURL)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("Token", text: $token)
                    Picker("Language", selection: $language) {
                        ForEach(languages, id: \.self) { Text($0) }
                    }
                    Button("Save") {
                        SolConfig.save(proxyURL: proxyURL, token: token, language: language)
                    }
                }

                Section("Microphone") {
                    Button(micGranted ? "Microphone allowed ✓" : "Allow microphone") {
                        Task { micGranted = await AudioRecorder.requestPermission() }
                    }.disabled(micGranted)
                }

                Section("Sol Keyboard") {
                    Label("Settings → General → Keyboard → Keyboards → Add New Keyboard → Sol", systemImage: "1.circle")
                    Label("Tap Sol → turn on Allow Full Access (needed for network + mic)", systemImage: "2.circle")
                    Label("In any app, long-press 🌐 and pick Sol, then tap the mic", systemImage: "3.circle")
                    Link("Open Settings", destination: URL(string: UIApplication.openSettingsURLString)!)
                }
            }
            .navigationTitle("Setup")
        }
    }
}
