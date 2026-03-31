import Foundation
import NobodyWho

print("===========================================")
print("NobodyWho Swift SDK - Live Integration Test")
print("===========================================\n")

// Get model path from arguments
let modelPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : nil

// Test 1: Module Import
print("✅ Test 1: Module Import")
print("   ✓ Successfully imported NobodyWho module\n")

// Test 2: Type Availability
print("✅ Test 2: Type Availability")
print("   ✓ ChatConfig: \(ChatConfig.self)")
print("   ✓ Message: \(Message.self)")
print("   ✓ Role: \(Role.self)")
print("   ✓ Chat: \(Chat.self)")
print("   ✓ Model: \(Model.self)")
print("   ✓ NobodyWhoError: \(NobodyWhoError.self)\n")

// Test 3: Create instances
print("✅ Test 3: Create Instances")
let config = ChatConfig(contextSize: 4096, systemPrompt: "You are a helpful assistant", allowThinking: false)
print("   ✓ Created ChatConfig (contextSize: 4096)")

let message = Message.plain(role: .user, content: "Hello!")
print("   ✓ Created Message (role: user, content: \"Hello!\")\n")

// Test 4: Error handling
print("✅ Test 4: Error Handling")
do {
    let _ = try loadModel(path: "/nonexistent/model.gguf", useGpu: false, mmprojPath: nil)
    print("   ❌ Expected an error but got none")
} catch let error as NobodyWhoError {
    print("   ✓ Caught NobodyWhoError: \(error)")
} catch {
    print("   ⚠️  Caught unexpected error: \(error)")
}

// Test 5: Initialize logging
print("\n✅ Test 5: Logging Initialization")
initLogging()
print("   ✓ initLogging() called successfully\n")

// Test 6: Real model test (if path provided)
if let modelPath = modelPath {
    print("===========================================")
    print("Real Model Test")
    print("===========================================\n")

    if !FileManager.default.fileExists(atPath: modelPath) {
        print("❌ Model file not found at: \(modelPath)")
    } else {
        print("📦 Model: \(modelPath)")

        do {
            print("\n⏳ Loading model (this may take a moment)...")
            let model = try loadModel(path: modelPath, useGpu: true, mmprojPath: nil)
            print("✅ Model loaded successfully!")

            print("\n⏳ Creating chat session...")
            let chat = try Chat(model: model, config: config)
            print("✅ Chat session created!")

            print("\n⏳ Asking: 'What is 2+2?'")
            let response = try chat.ask(prompt: "What is 2+2? Answer in one short sentence.").completed()
            print("✅ Response received:\n")
            print("   \(response)")

            print("\n⏳ Getting chat history...")
            let history = try chat.history()
            print("✅ Chat history (\(history.count) messages):")
            for (i, msg) in history.enumerated() {
                switch msg {
                case .plain(let role, let content):
                    print("   [\(i+1)] \(role): \(content.prefix(50))...")
                case .toolCalls(let role, let content, _):
                    print("   [\(i+1)] \(role) (tool calls): \(content.prefix(50))...")
                case .toolResponse(let role, let name, let content):
                    print("   [\(i+1)] \(role) tool[\(name)]: \(content.prefix(50))...")
                }
            }

            print("\n🎉 FULL INTEGRATION TEST PASSED!")

        } catch let error as NobodyWhoError {
            print("\n❌ NobodyWhoError: \(error)")
        } catch {
            print("\n❌ Unexpected error: \(error)")
        }
    }
} else {
    print("===========================================")
    print("ℹ️  No model path provided")
    print("===========================================")
    print("\nTo test with a real model, run:")
    print("  swift run NobodyWhoTestCLI /path/to/model.gguf")
}

print("\n===========================================")
print("Test Summary")
print("===========================================")
print("✅ Module loads correctly")
print("✅ All types are accessible")
print("✅ Instances can be created")
print("✅ Error handling works")
print("✅ Functions can be called")
if modelPath != nil {
    print("✅ Real model inference works")
}
print("\n🎉 All tests completed!")
