import SwiftUI

struct SettingsView: View {
    var isInitialSetup: Bool = false

    @State private var serverURL: String = KeychainService.load("serverURL") ?? ""
    @State private var apiKey: String = KeychainService.load("apiKey") ?? ""
    @State private var connectionStatus: ConnectionStatus = .idle
    @State private var connectionError: String = ""
    @AppStorage("colorScheme") private var colorSchemeRaw: String = "system"
    @AppStorage("accentColorHex") private var accentColorHex: String = "007AFF"

    @Environment(\.dismiss) private var dismiss

    enum ConnectionStatus {
        case idle, checking, ok, fail
        var label: String {
            switch self { case .idle: ""; case .checking: "Checking…"; case .ok: "Connected ✓"; case .fail: "Failed ✗" }
        }
        var color: Color {
            switch self { case .ok: .green; case .fail: .red; default: .secondary }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    TextField("Server URL", text: $serverURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("iOS API Key", text: $apiKey)
                    HStack {
                        Button("Test connection") { Task { await testConnection() } }
                        Spacer()
                        if connectionStatus != .idle {
                            Text(connectionStatus.label)
                                .foregroundStyle(connectionStatus.color)
                                .font(.caption)
                        }
                    }
                    if !connectionError.isEmpty {
                        Text(connectionError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: $colorSchemeRaw) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.3")
                    LabeledContent("Server", value: serverURL.isEmpty ? "Not set" : serverURL)
                }
            }
            .navigationTitle(isInitialSetup ? "Welcome" : "Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(isInitialSetup ? "Save & Continue" : "Save") {
                        save()
                        if !isInitialSetup { dismiss() }
                    }
                    .fontWeight(.semibold)
                    .disabled(serverURL.isEmpty || apiKey.isEmpty)
                }
            }
        }
    }

    private func save() {
        KeychainService.save(serverURL, for: "serverURL")
        KeychainService.save(apiKey, for: "apiKey")
    }

    private func testConnection() async {
        save()
        connectionStatus = .checking
        let (ok, error) = await APIService.shared.checkHealth()
        connectionStatus = ok ? .ok : .fail
        connectionError = error ?? ""
    }
}
