# JobSearchChat

Agentic job search on the dev.bg job board.

A lightweight iOS‑only SwiftUI chat app that runs Qwen3‑4B on device via MLX and calls a `get_todays_jobs` tool to fetch dev.bg job listings.

## Features

- On‑device Qwen3‑4B (4‑bit) inference
- Tool calling for job search (`get_todays_jobs`)
- Markdown rendering with tappable links
- Model download on first use (cached in `~/Library/Caches/huggingface` on iOS)

## Requirements

- iOS 18+
- Xcode 15+
- Swift 5.9+

## Dependencies

- `mlx-swift-lm` (MLXLLM, MLXLMCommon)
- `SwiftSoup` (HTML parsing for dev.bg)

## Using In Xcode

1. Open `JobSearchChat.xcodeproj`.
2. Select the **JobSearchChat** scheme and run on an iPhone simulator/device.
3. If Xcode asks for signing, set your Team and update the bundle identifier.

## Regenerating the Project

If you edit `project.yml`, re-run:

```bash
xcodegen
```

## Notes

- The model used is `qwen3:4b` from `LLMRegistry.qwen3_4b_4bit`.
- The system prompt guides the model to call `get_todays_jobs` when it has category/date.
