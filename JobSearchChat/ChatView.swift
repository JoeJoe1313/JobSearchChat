import SwiftUI

struct ChatView: View {
    @Bindable private var vm: ChatViewModel

    init(viewModel: ChatViewModel) {
        self.vm = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ConversationView(messages: vm.messages)

                Divider()

                PromptField(prompt: $vm.prompt) {
                    await vm.generate()
                }
                .padding()
            }
            .navigationTitle("Job Search Chat")
            .toolbar {
                ChatToolbarView(vm: vm)
            }
        }
    }
}

#Preview {
    ChatView(viewModel: ChatViewModel(mlxService: MLXService()))
}
