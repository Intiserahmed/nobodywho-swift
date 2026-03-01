# NobodyWho SDK - Example App

A beautiful, simple SwiftUI chat interface showcasing all capabilities of the NobodyWho SDK.

## ✨ Features

### SDK Capabilities Demonstrated

1. **Model Loading**
   - ✅ Load GGUF models from bundle
   - ✅ GPU acceleration toggle
   - ✅ Real-time loading status

2. **Chat Interface**
   - ✅ Interactive Q&A with AI
   - ✅ Message history display
   - ✅ Blocking (synchronous) responses
   - ✅ Error handling

3. **Configuration**
   - ✅ Adjustable context size (512-8192)
   - ✅ Custom system prompts
   - ✅ Quick preset configurations
   - ✅ Runtime reconfiguration

4. **User Experience**
   - ✅ Clean, modern chat UI
   - ✅ Quick demo prompts
   - ✅ Typing indicator
   - ✅ Message timestamps
   - ✅ Settings panel

## 🚀 Getting Started

### Prerequisites

1. **Add the model file:**
   - Download a GGUF model (e.g., `Qwen_Qwen3-0.6B-Q4_K_M.gguf`)
   - Add to Xcode project
   - Ensure it's in "Copy Bundle Resources"

2. **NobodyWho SDK:**
   - Already configured via Swift Package Manager
   - URL: `https://github.com/Intiserahmed/nobodywho-swift`

### Build & Run

```bash
# Open in Xcode
open Example.xcodeproj

# Or via command line
xcodebuild -scheme Example -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## 📱 App Structure

```
Example/
├── ContentView.swift       # Main chat interface
├── Models.swift           # Data models (ChatMessage, DemoPrompt)
├── ExampleApp.swift       # App entry point
└── README.md             # This file
```

### Key Components

#### ContentView
- Main chat interface
- SDK initialization
- Message handling
- Settings management

#### ModelStatusBar
- Shows model loading state
- GPU status indicator
- Quick access to settings

#### MessageBubble
- User vs AI message display
- Timestamps
- Responsive layout

#### QuickPromptsView
- Pre-made demo prompts
- Showcases different use cases
- Easy to customize

#### SettingsView
- System prompt editor
- Context size slider
- Quick presets
- GPU toggle

## 🎯 SDK Usage Examples

### Initialize SDK

```swift
// 1. Initialize logging
initLogging()

// 2. Load model
let model = try loadModel(path: modelPath, useGpu: true)

// 3. Create chat with config
let config = ChatConfig(
    contextSize: 2048,
    systemPrompt: "You are a helpful assistant."
)
let chat = try Chat(model: model, config: config)

// 4. Ask questions
let response = try chat.askBlocking(prompt: "What is 2+2?")
```

### Get Chat History

```swift
let history = try chat.history()
for message in history {
    print("[\(message.role)] \(message.content)")
}
```

### Change Configuration

```swift
// Create new chat with different config
let newConfig = ChatConfig(
    contextSize: 4096,
    systemPrompt: "You are a math tutor."
)
let newChat = try Chat(model: model, config: newConfig)
```

## 🎨 Customization

### Add Custom Demo Prompts

Edit `Models.swift`:

```swift
DemoPrompt(
    icon: "🎵",
    title: "Music",
    prompt: "Recommend a song for a rainy day",
    category: "Entertainment"
)
```

### Modify System Prompts

Edit preset prompts in `SettingsView`:

```swift
Button("🎮 Game Designer") {
    systemPrompt = "You are a creative game designer..."
}
```

### Change Theme Colors

In `MessageBubble`:

```swift
.background(message.isUser ? Color.purple : Color(.systemGray5))
```

## 📊 Performance Tips

1. **Context Size:**
   - Smaller = Faster responses
   - Larger = More context retained
   - Recommended: 2048 for general use

2. **GPU Acceleration:**
   - Enable for faster inference
   - Disable if running on older devices

3. **Model Selection:**
   - Smaller models (<1GB) = Faster
   - Larger models = Better quality

## 🐛 Troubleshooting

### Model Not Found
- Ensure GGUF file is in project
- Check "Copy Bundle Resources" in Build Phases
- Verify filename matches exactly

### Slow Responses
- Reduce context size
- Enable GPU acceleration
- Try a smaller model

### Out of Memory
- Lower context size (try 1024)
- Close other apps
- Use smaller model

## 📚 Documentation

- **SDK Docs:** [NobodyWho SDK](https://github.com/Intiserahmed/nobodywho-swift)
- **Model Formats:** GGUF (llama.cpp compatible)
- **SwiftUI:** [Apple Documentation](https://developer.apple.com/documentation/swiftui)

## 🤝 Contributing

This is an example app. Feel free to fork and customize for your needs!

## 📄 License

Same as NobodyWho SDK - Check main repository for license details.

---

**Built with ❤️ using NobodyWho SDK**
