import Foundation

@Observable
class Message: Identifiable {
    let id: UUID
    let role: Role
    var content: String
    let timestamp: Date

    init(role: Role, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = .now
    }

    enum Role {
        case user
        case assistant
        case system
        case tool
    }
}

extension Message {
    static func user(_ content: String) -> Message {
        Message(role: .user, content: content)
    }

    static func assistant(_ content: String) -> Message {
        Message(role: .assistant, content: content)
    }

    static func system(_ content: String) -> Message {
        Message(role: .system, content: content)
    }

    static func tool(_ content: String) -> Message {
        Message(role: .tool, content: content)
    }
}
