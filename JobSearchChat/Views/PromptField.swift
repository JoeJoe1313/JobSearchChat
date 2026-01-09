import SwiftUI

struct PromptField: View {
    @Binding var prompt: String
    @State private var task: Task<Void, Never>?

    let sendButtonAction: () async -> Void

    var body: some View {
        HStack {
            TextField("Message", text: $prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

            Button {
                if isRunning {
                    task?.cancel()
                    removeTask()
                } else {
                    task = Task {
                        await sendButtonAction()
                        removeTask()
                    }
                }
            } label: {
                Image(systemName: isRunning ? "stop.circle.fill" : "paperplane.fill")
            }
            .keyboardShortcut(isRunning ? .cancelAction : .defaultAction)
        }
    }

    private var isRunning: Bool {
        task != nil && !(task!.isCancelled)
    }

    private func removeTask() {
        task = nil
    }
}

#Preview {
    PromptField(prompt: .constant("")) {
    }
}
