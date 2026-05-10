import SwiftUI

struct SettingsView: View {
    var isInitialSetup: Bool = false

    @State private var serverURL: String = KeychainService.load("serverURL") ?? ""
    @State private var apiKey: String = KeychainService.load("apiKey") ?? ""
    @State private var connectionStatus: ConnectionStatus = .idle
    @State private var connectionError: String = ""
    @AppStorage("colorScheme") private var colorSchemeRaw: String = "system"

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
                    HStack(spacing: 12) {
                        SettingsIcon(systemImage: "network", color: .blue)
                        TextField("Server URL", text: $serverURL)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    HStack(spacing: 12) {
                        SettingsIcon(systemImage: "key.fill", color: Color(.systemGray))
                        SecureField("iOS API Key", text: $apiKey)
                    }
                    HStack(spacing: 12) {
                        SettingsIcon(systemImage: "antenna.radiowaves.left.and.right", color: .green)
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
                            .padding(.leading, 40)
                    }
                }

                Section("Appearance") {
                    HStack(spacing: 12) {
                        SettingsIcon(systemImage: "paintbrush.fill", color: .purple)
                        Picker("Theme", selection: $colorSchemeRaw) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                    }
                }

                Section("About") {
                    HStack(spacing: 12) {
                        SettingsIcon(systemImage: "info.circle", color: Color(.systemGray))
                        LabeledContent("Version", value: "1.1.0")
                    }
                    HStack(spacing: 12) {
                        SettingsIcon(systemImage: "server.rack", color: Color(.systemGray2))
                        LabeledContent("Server", value: serverURL.isEmpty ? "Not set" : serverURL)
                    }
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
        KeychainService.save(serverURL.trimmingCharacters(in: .whitespacesAndNewlines), for: "serverURL")
        KeychainService.save(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), for: "apiKey")
    }

    private func testConnection() async {
        save()
        connectionStatus = .checking
        let (ok, error) = await APIService.shared.checkHealth()
        connectionStatus = ok ? .ok : .fail
        connectionError = error ?? ""
    }
}

private struct SettingsIcon: View {
    let systemImage: String
    let color: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color, in: RoundedRectangle(cornerRadius: 6))
    }
}
