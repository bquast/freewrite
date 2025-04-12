// DocumentState.swift
import SwiftUI
import AppKit
import Combine // Import Combine

class DocumentState: ObservableObject {
    @Published var text: String = ""
    @Published var fileURL: URL? = nil
    @Published var hasUnsavedChanges: Bool = false // Track changes

    // --- Find/Replace State ---
    @Published var showFindReplacePanel: Bool = false
    @Published var findText: String = ""
    @Published var replaceText: String = ""
    // Optional states for displaying results:
    @Published var findResultCount: Int = 0 
    @Published var currentFindResultIndex: Int = 0

    // --- Statistics State ---
    @Published var showStatisticsAlert: Bool = false
    @Published var characterCount: Int = 0
    @Published var wordCount: Int = 0

    private var cancellables = Set<AnyCancellable>() // For Combine sink
    private var initialLoadComplete = false // Flag to track initial loading/saving

    init(text: String = "", fileURL: URL? = nil) {
        self.text = text
        self.fileURL = fileURL
        // Observe text changes to mark unsaved changes
        $text.sink { [weak self] _ in
             if self?.initialLoadComplete == true { // Only mark dirty after initial load/save
                 print("Text changed, marking unsaved.")
                 self?.hasUnsavedChanges = true
             }
        }.store(in: &cancellables)

        // Defer setting initialLoadComplete to avoid marking initial state as dirty
         DispatchQueue.main.async { 
             self.initialLoadComplete = true 
             print("Initial load complete.")
         }
    }

    // --- File Actions ---

    func newDocument() {
        // TODO: Check for unsaved changes before discarding
        print("Executing newDocument...")
        self.initialLoadComplete = false // Prevent marking state dirty
        self.text = ""
        self.fileURL = nil
        self.hasUnsavedChanges = false
         DispatchQueue.main.async { self.initialLoadComplete = true } // Rearm flag
        print("New document created.")
    }

    func openDocument() {
        // TODO: Check for unsaved changes
        print("Executing openDocument...")
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.plainText] // Allow only .txt
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK {
            guard let url = openPanel.url else { return }
            do {
                let loadedText = try String(contentsOf: url, encoding: .utf8)
                self.initialLoadComplete = false // Prevent marking state dirty
                self.fileURL = url
                self.text = loadedText
                self.hasUnsavedChanges = false // Mark as saved initially
                DispatchQueue.main.async { self.initialLoadComplete = true } // Rearm flag
                print("Document opened from: \(url.path)")
            } catch {
                print("Error opening document: \(error.localizedDescription)")
                // TODO: Show error alert to user
            }
        }
    }

    func saveDocument() {
        print("Executing saveDocument...")
        guard hasUnsavedChanges else {
            print("No changes to save.")
            return
        }

        if let url = fileURL {
            // Save to existing file URL
            saveText(to: url)
        } else {
            // No URL, perform Save As
            saveDocumentAs()
        }
    }

    func saveDocumentAs() {
        print("Executing saveDocumentAs...")
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = fileURL?.lastPathComponent ?? "Untitled.txt" // Suggest name

        if savePanel.runModal() == .OK {
            guard let url = savePanel.url else { return }
            // Ensure .txt extension
            let finalURL = url.pathExtension.lowercased() == "txt" ? url : url.appendingPathExtension("txt")
            saveText(to: finalURL)
            // No need to set fileURL here, saveText does it indirectly via sink?
            // Explicitly set it after successful save
            // self.fileURL = finalURL // Let saveText handle this via state update?
            // No, saveText doesn't update fileURL state directly.
        }
    }

    private func saveText(to url: URL) {
        print("Executing saveText to \(url.path)...")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            self.initialLoadComplete = false // Prevent marking state dirty
            self.fileURL = url // Update fileURL state *after* successful save
            self.hasUnsavedChanges = false // Mark as saved
            DispatchQueue.main.async { self.initialLoadComplete = true } // Rearm flag
            print("Document saved successfully.")
        } catch {
            print("Error saving document: \(error.localizedDescription)")
            // TODO: Show error alert to user
        }
    }

    // MARK: - Statistics
    func calculateStatistics() {
        let currentText = self.text
        self.characterCount = currentText.count
        // Simple word count based on whitespace and newlines
        self.wordCount = currentText.split { $0.isWhitespace || $0.isNewline }.filter { !$0.isEmpty }.count // Filter empty strings after split
        // Show the alert by updating the state
        self.showStatisticsAlert = true
        print("Calculated Statistics: Chars=\(characterCount), Words=\(wordCount)")
    }
}
