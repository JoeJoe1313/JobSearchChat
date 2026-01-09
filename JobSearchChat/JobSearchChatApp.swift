import SwiftUI

@main
struct JobSearchChatApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView(viewModel: ChatViewModel(mlxService: MLXService()))
        }
    }
}
