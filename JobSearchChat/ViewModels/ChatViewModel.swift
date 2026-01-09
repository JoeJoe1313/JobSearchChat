import Foundation
import MLXLMCommon

@Observable
@MainActor
class ChatViewModel {
    private let mlxService: MLXService
    private let tool = JobSearchTool.tool
    private let maxToolTurns = 2
    private static let systemPrompt =
        "You are a job search assistant for dev.bg. "
        + "When you have a category and date, call get_todays_jobs. "
        + "If details are missing, ask the user. "
        + "When calling a tool, reply only with a <tool_call> JSON block like "
        + "<tool_call>{\\\"name\\\":\\\"get_todays_jobs\\\",\\\"arguments\\\":{...}}</tool_call>. "
        + "Return results in markdown."

    init(mlxService: MLXService) {
        self.mlxService = mlxService
    }

    var prompt: String = ""

    var messages: [Message] = [
        .system(ChatViewModel.systemPrompt)
    ]

    var selectedModel: LMModel = MLXService.availableModels.first!

    var isGenerating = false
    private var generateTask: Task<Void, any Error>?

    private var generateCompletionInfo: GenerateCompletionInfo?

    var tokensPerSecond: Double {
        generateCompletionInfo?.tokensPerSecond ?? 0
    }

    var modelDownloadProgress: Progress? {
        mlxService.modelDownloadProgress
    }

    var errorMessage: String?

    private var toolTurnCount = 0

    func generate() async {
        if let existingTask = generateTask {
            existingTask.cancel()
            generateTask = nil
        }

        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isGenerating = true
        toolTurnCount = 0

        messages.append(.user(trimmed))
        messages.append(.assistant(""))
        clear(.prompt)

        generateTask = Task {
            try await runGenerationLoop()
        }

        do {
            try await withTaskCancellationHandler {
                try await generateTask?.value
            } onCancel: {
                Task { @MainActor in
                    generateTask?.cancel()
                    if let assistantMessage = messages.last {
                        assistantMessage.content += "\n[Cancelled]"
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
        generateTask = nil
    }

    private func runGenerationLoop() async throws {
        var detectedToolCall: ToolCall?

        let stream = try await mlxService.generate(
            messages: messages,
            model: selectedModel,
            tools: [tool.schema]
        )

        for await event in stream {
            if let output = event.chunk, let assistantMessage = messages.last {
                assistantMessage.content += output
            }

            if let info = event.info {
                generateCompletionInfo = info
            }

            if let toolCall = event.toolCall {
                detectedToolCall = toolCall
                break
            }
        }

        if let toolCall = detectedToolCall {
            try await handleToolCall(toolCall)
        }
    }

    private func handleToolCall(_ toolCall: ToolCall) async throws {
        toolTurnCount += 1
        guard toolTurnCount <= maxToolTurns else {
            messages.append(.assistant("Tool call limit reached."))
            return
        }

        if let last = messages.last, last.role == .assistant, last.content.isEmpty {
            messages.removeLast()
        }

        let output = try await toolCall.execute(with: tool)
        messages.append(.tool(output.toolResult))
        messages.append(.assistant(""))

        try await runGenerationLoop()
    }

    func clear(_ options: ClearOption) {
        if options.contains(.prompt) {
            prompt = ""
        }

        if options.contains(.chat) {
            messages = [.system(ChatViewModel.systemPrompt)]
            generateTask?.cancel()
        }

        if options.contains(.meta) {
            generateCompletionInfo = nil
        }

        errorMessage = nil
    }
}

struct ClearOption: RawRepresentable, OptionSet {
    let rawValue: Int

    static let prompt = ClearOption(rawValue: 1 << 0)
    static let chat = ClearOption(rawValue: 1 << 1)
    static let meta = ClearOption(rawValue: 1 << 2)
}
