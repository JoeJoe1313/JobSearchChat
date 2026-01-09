@MainActor
struct SampleData {
    static let conversation: [Message] = [
        .system("You are a job search assistant for dev.bg."),
        .user("Find data science roles for today"),
        .assistant("Looking up data science roles posted today on dev.bg..."),
        .tool("Found 3 jobs in 'Data Science' category for 2025-01-10:\n\n1. Data Scientist\n   Company: Example Co\n   Posted: 10 \u{044f}\u{043d}.\n   Link: https://dev.bg/..."),
        .assistant("Here are the latest data science roles for today. Let me know if you want another category or date."),
    ]
}
