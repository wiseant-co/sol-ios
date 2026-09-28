import UIKit
import SolKit

/// The Sol Keyboard: a minimal custom keyboard whose job is one big mic button. Tap to record, tap
/// to stop; the audio goes to the proxy and the returned text is inserted into the focused field via
/// `textDocumentProxy` — the iOS way to "type into any app".
///
/// Requires **Full Access** (RequestsOpenAccess) for the network call and the mic. If it's off, or
/// the host app hasn't been configured, the keyboard shows a hint instead.
final class KeyboardViewController: UIInputViewController {
    private let recorder = AudioRecorder()
    private var isRecording = false

    private let micButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let nextButton = UIButton(type: .system)

    private let amber = UIColor(red: 0.96, green: 0.70, blue: 0.12, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.secondarySystemBackground

        micButton.setImage(UIImage(systemName: "mic.circle.fill",
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 44)), for: .normal)
        micButton.tintColor = amber
        micButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)

        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center

        nextButton.setTitle("🌐", for: .normal)
        nextButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)

        let stack = UIStackView(arrangedSubviews: [micButton, statusLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 190),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
        ])

        refreshHint()
    }

    private func refreshHint() {
        if !hasFullAccess {
            statusLabel.text = "Turn on “Allow Full Access” for Sol in Settings"
            micButton.isEnabled = false
        } else if !SolConfig.load().isConfigured {
            statusLabel.text = "Open the Sol app to sign in first"
            micButton.isEnabled = false
        } else {
            statusLabel.text = "Tap to dictate"
            micButton.isEnabled = true
        }
    }

    @objc private func toggle() {
        if isRecording { Task { await finish() } } else { begin() }
    }

    private func begin() {
        do {
            try recorder.start()
            isRecording = true
            statusLabel.text = "Listening… tap to stop"
            micButton.tintColor = .systemRed
        } catch {
            statusLabel.text = "Mic error"
        }
    }

    private func finish() async {
        isRecording = false
        micButton.tintColor = amber
        statusLabel.text = "Transcribing…"
        let wav = recorder.stop()
        do {
            let result = try await ProxyClient(config: .load()).transcribe(wav: wav)
            if !result.text.isEmpty { textDocumentProxy.insertText(result.text) }
            statusLabel.text = "Tap to dictate"
        } catch {
            statusLabel.text = "Failed — check connection"
        }
    }
}
