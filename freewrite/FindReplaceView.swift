// FindReplaceView.swift
import SwiftUI

struct FindReplaceView: View {
    @EnvironmentObject var documentState: DocumentState
    // Callbacks for actions to be implemented in ContentView/DocumentState
    var onFindNext: () -> Void
    var onFindPrevious: () -> Void
    var onReplace: () -> Void
    var onReplaceAll: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            // Find Field
            TextField("Find", text: $documentState.findText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(minWidth: 150)
                .onSubmit { // Trigger find next on enter in find field
                    if !documentState.findText.isEmpty {
                        onFindNext()
                    }
                }

            // Navigation Buttons
            Button(action: onFindPrevious) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(BorderlessButtonStyle()) // Use Borderless for subtle icon buttons
            .disabled(documentState.findText.isEmpty)

            Button(action: onFindNext) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(documentState.findText.isEmpty)

            // Optional: Display match count (implement later)
            // Text("\(documentState.currentFindResultIndex) of \(documentState.findResultCount)")
            //     .font(.caption)
            //     .foregroundColor(.gray)

            // Replace Field
            TextField("Replace with", text: $documentState.replaceText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(minWidth: 150)
                 .onSubmit { // Trigger replace next on enter in replace field
                    if !documentState.findText.isEmpty {
                         onReplace()
                    }
                 }

            // Action Buttons
            Button("Replace", action: onReplace)
                .disabled(documentState.findText.isEmpty)

            Button("Replace All", action: onReplaceAll)
                .disabled(documentState.findText.isEmpty)

            Spacer() // Pushes Done button to the right

            // Done Button
            Button("Done") {
                documentState.showFindReplacePanel = false
            }
            // Make Done button prominent or use standard close button?
            // For now, a simple button.
        }
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
        // .background(Color(NSColor.windowBackgroundColor)) // Alt background
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.2), radius: 3, y: 2)
        .frame(maxWidth: .infinity) // Take full width at the top/bottom
    }
}

// Helper for background material
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) { }
}


// Preview Provider (optional)
struct FindReplaceView_Previews: PreviewProvider {
    static var previews: some View {
        FindReplaceView(
            onFindNext: { print("Find Next") },
            onFindPrevious: { print("Find Prev") },
            onReplace: { print("Replace") },
            onReplaceAll: { print("Replace All") }
        )
        .environmentObject(DocumentState()) // Provide a dummy state for preview
        .padding()
        .frame(width: 600)
    }
}
