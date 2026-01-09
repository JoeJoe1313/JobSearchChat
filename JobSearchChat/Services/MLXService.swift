import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import Tokenizers

@Observable
class MLXService {
    static let availableModels: [LMModel] = [
        LMModel(name: "qwen3:4b", configuration: LLMRegistry.qwen3_4b_4bit, type: .llm)
    ]

    private let modelCache = NSCache<NSString, ModelContainer>()

    @MainActor
    private(set) var modelDownloadProgress: Progress?

    private func load(model: LMModel) async throws -> ModelContainer {
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

        if let container = modelCache.object(forKey: model.name as NSString) {
            return container
        }

        let container = try await LLMModelFactory.shared.loadContainer(
            hub: .default,
            configuration: model.configuration
        ) { progress in
            Task { @MainActor in
                self.modelDownloadProgress = progress
            }
        }

        modelCache.setObject(container, forKey: model.name as NSString)
        return container
    }

    func generate(
        messages: [Message],
        model: LMModel,
        tools: [ToolSpec]?
    ) async throws -> AsyncStream<Generation> {
        let modelContainer = try await load(model: model)

        let chat = messages.map { message in
            let role: Chat.Message.Role =
                switch message.role {
                case .assistant:
                    .assistant
                case .user:
                    .user
                case .system:
                    .system
                case .tool:
                    .tool
                }

            return Chat.Message(role: role, content: message.content)
        }

        let userInput = UserInput(chat: chat, tools: tools)

        return try await modelContainer.perform { (context: ModelContext) in
            let lmInput = try await context.processor.prepare(input: userInput)
            let parameters = GenerateParameters(temperature: 0.7)
            return try MLXLMCommon.generate(
                input: lmInput,
                parameters: parameters,
                context: context
            )
        }
    }
}
