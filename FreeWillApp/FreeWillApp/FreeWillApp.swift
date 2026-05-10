import SwiftUI

@main
struct FreeWillApp: App {
    var body: some Scene {
        WindowGroup {
            if KeychainService.load("serverURL") != nil,
               KeychainService.load("apiKey") != nil {
                ContentView()
            } else {
                SettingsView(isInitialSetup: true)
            }
        }
    }
}
