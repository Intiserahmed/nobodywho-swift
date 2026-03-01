//
//  SettingsView.swift
//  Example
//
//  Settings and configuration screen
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var systemPrompt: String
    @Binding var contextSize: UInt32
    @Binding var useGPU: Bool
    let onApply: () -> Void

    var body: some View {
        NavigationView {
            Form {
                // Model Configuration Section
                Section {
                    Toggle("Use GPU Acceleration", isOn: $useGPU)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Context Size")
                            Spacer()
                            Text("\(contextSize)")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: Binding(
                            get: { Double(contextSize) },
                            set: { contextSize = UInt32($0) }
                        ), in: 512...8192, step: 512)

                        Text("Higher = More context retained, slower responses")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Model Configuration")
                } footer: {
                    Text("Changes will be applied when you tap 'Apply'")
                }

                // System Prompt Section
                Section {
                    TextEditor(text: $systemPrompt)
                        .frame(height: 120)
                        .font(.body)

                    Button("Reset to Default") {
                        systemPrompt = "You are a helpful AI assistant."
                    }
                    .font(.callout)
                } header: {
                    Text("System Prompt")
                } footer: {
                    Text("Defines the AI's personality and behavior")
                }

                // Quick Presets Section
                Section("Quick Presets") {
                    PresetButton(
                        icon: "bubble.left.and.bubble.right",
                        title: "General Assistant",
                        description: "Helpful and balanced"
                    ) {
                        systemPrompt = "You are a helpful AI assistant."
                    }

                    PresetButton(
                        icon: "function",
                        title: "Math Tutor",
                        description: "Step-by-step explanations"
                    ) {
                        systemPrompt = "You are a patient math tutor. Explain step by step and show your work."
                    }

                    PresetButton(
                        icon: "chevron.left.forwardslash.chevron.right",
                        title: "Code Helper",
                        description: "Clean, commented code"
                    ) {
                        systemPrompt = "You are an expert programmer. Provide clean, well-commented code with best practices."
                    }

                    PresetButton(
                        icon: "pencil.and.outline",
                        title: "Creative Writer",
                        description: "Imaginative and descriptive"
                    ) {
                        systemPrompt = "You are a creative writer. Be imaginative, descriptive, and engaging."
                    }

                    PresetButton(
                        icon: "graduationcap",
                        title: "Teacher",
                        description: "Patient and educational"
                    ) {
                        systemPrompt = "You are a patient teacher. Explain concepts clearly with examples."
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PresetButton: View {
    let icon: String  // SF Symbol name
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(
        systemPrompt: .constant("You are a helpful assistant."),
        contextSize: .constant(2048),
        useGPU: .constant(true),
        onApply: {}
    )
}
