import SwiftUI

struct ChatToolbarView: View {
    @Bindable var vm: ChatViewModel

    var body: some View {
        if let errorMessage = vm.errorMessage {
            ErrorView(errorMessage: errorMessage)
        }

        if let progress = vm.modelDownloadProgress, !progress.isFinished {
            DownloadProgressView(progress: progress)
        }

        Button {
            vm.clear([.chat, .meta])
        } label: {
            GenerationInfoView(tokensPerSecond: vm.tokensPerSecond)
        }

        Text(vm.selectedModel.displayName)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
