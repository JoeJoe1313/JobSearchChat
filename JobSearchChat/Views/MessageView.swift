import SwiftUI

struct MarkdownText: View {
    let text: String

    var body: some View {
        if let attributed = try? AttributedString(markdown: text) {
            Text(attributed)
        } else {
            Text(text)
        }
    }
}

struct MessageView: View {
    let message: Message

    init(_ message: Message) {
        self.message = message
    }

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer()
                MarkdownText(text: message.content)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.tint, in: .rect(cornerRadius: 16))
                    .textSelection(.enabled)
            }

        case .assistant:
            HStack {
                MarkdownText(text: message.content)
                    .textSelection(.enabled)
                Spacer()
            }

        case .tool:
            HStack {
                MarkdownText(text: message.content)
                    .font(.callout)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.secondary.opacity(0.15), in: .rect(cornerRadius: 12))
                    .textSelection(.enabled)
                Spacer()
            }

        case .system:
            Label(message.content, systemImage: "desktopcomputer")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MessageView(.system("You are a job search assistant."))
        MessageView(.user("Find data science roles for today"))
        MessageView(.assistant("Here are the results..."))
        MessageView(.tool("Tool result: 3 jobs found"))
    }
    .padding()
}
