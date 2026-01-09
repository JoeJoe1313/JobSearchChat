import SwiftUI

struct ConversationView: View {
    let messages: [Message]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(messages) { message in
                    MessageView(message)
                        .padding(.horizontal, 12)
                }
            }
        }
        .padding(.vertical, 8)
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
    }
}

#Preview {
    ConversationView(messages: SampleData.conversation)
}
