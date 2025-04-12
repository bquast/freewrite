// Swift 5.0
//
//  ContentView.swift
//  freewrite
//
//  Created by thorfinn on 2/14/25.
//

import SwiftUI
import AppKit
import Combine

struct ContentView: View {
    // Use EnvironmentObject for document state
    @EnvironmentObject var documentState: DocumentState
    
    @State private var selectedFont: String = "Lato-Regular"
    @State private var hoveredFont: String? = nil
    @State private var isHoveringSize = false
    @State private var fontSize: CGFloat = 18
    @State private var bottomNavOpacity: Double = 1.0
    @State private var isHoveringBottomNav = false
    
    @State private var cursorPosition: (line: Int, column: Int) = (1, 1)
    @State private var nsTextView: NSTextView? = nil
    
    let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26]
    
    var body: some View {
        let buttonBackground = Color.white
        let navHeight: CGFloat = 68
        
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if documentState.showFindReplacePanel {
                    FindReplaceView(
                        onFindNext: findNext,
                        onFindPrevious: findPrevious,
                        onReplace: replace,
                        onReplaceAll: replaceAll
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    Divider()
                }
                
                TextEditor(text: $documentState.text)
                    .font(.custom(selectedFont, size: fontSize))
                    .foregroundColor(Color(red: 0.20, green: 0.20, blue: 0.20))
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.never)
                    .lineSpacing(fontSize * 0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
                    .colorScheme(.light)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let textView = NSApp.keyWindow?.contentView?.findSubview(ofType: NSTextView.self) {
                                self.nsTextView = textView
                                textView.delegate = self.makeCoordinator()
                                self.updateCursorPosition(textView: textView)
                                print("NSTextView found and delegate set.")
                            } else {
                                print("Warning: NSTextView not found.")
                            }
                        }
                    }
            }
            
            VStack {
                Spacer()
                HStack {
                    HStack(spacing: 8) {
                        Button("\(Int(fontSize))px") {
                            if let currentIndex = fontSizes.firstIndex(of: fontSize) {
                                let nextIndex = (currentIndex + 1) % fontSizes.count
                                fontSize = fontSizes[nextIndex]
                            } else {
                                fontSize = fontSizes.first ?? 18
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(isHoveringSize ? .black : .gray)
                        .onHover { hovering in
                            isHoveringSize = hovering
                            isHoveringBottomNav = hovering
                            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }

                        Text("•").foregroundColor(.gray)

                        Button("Lato") {
                            selectedFont = "Lato-Regular"
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(hoveredFont == "Lato" ? .black : .gray)
                        .onHover { hovering in
                            hoveredFont = hovering ? "Lato" : nil
                            isHoveringBottomNav = hovering
                            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }

                        Button("Arial") {
                            selectedFont = "Arial"
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(hoveredFont == "Arial" ? .black : .gray)
                        .onHover { hovering in
                            hoveredFont = hovering ? "Arial" : nil
                            isHoveringBottomNav = hovering
                            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }

                        Button("System") {
                            selectedFont = ".AppleSystemUIFont"
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(hoveredFont == "System" ? .black : .gray)
                        .onHover { hovering in
                            hoveredFont = hovering ? "System" : nil
                            isHoveringBottomNav = hovering
                            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }

                        Button("Serif") {
                            selectedFont = "Times New Roman"
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(hoveredFont == "Serif" ? .black : .gray)
                        .onHover { hovering in
                            hoveredFont = hovering ? "Serif" : nil
                            isHoveringBottomNav = hovering
                            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }
                    }
                    .padding(8)
                    .cornerRadius(6)
                    .onHover { hovering in
                        isHoveringBottomNav = hovering
                    }

                    Spacer()

                    Text("Line: \(cursorPosition.line), Col: \(cursorPosition.column)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.white)
                .opacity(bottomNavOpacity)
                .onHover { hovering in
                    isHoveringBottomNav = hovering
                    withAnimation(.easeOut(duration: 0.2)) {
                        bottomNavOpacity = 1.0
                    }
                }
            }
        }
        .onChange(of: documentState.text) { _ in
            if let textView = self.nsTextView {
                self.updateCursorPosition(textView: textView)
            }
        }
        .alert("Document Statistics", isPresented: $documentState.showStatisticsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Characters: \(documentState.characterCount)\nWords: \(documentState.wordCount)")
        }
    }
    
    // --- Find/Replace Actions ---
    
    func findNext() {
        print("Action: Find Next")
        guard let textView = nsTextView,
              let content = textView.string as NSString?,
              !documentState.findText.isEmpty else { return }

        let searchString = documentState.findText
        let currentRange = textView.selectedRange()
        // Start searching immediately after the current selection
        var searchRangeLocation = currentRange.location + currentRange.length
        // Ensure location is within bounds
        if searchRangeLocation > content.length { searchRangeLocation = content.length }
        
        var searchRange = NSRange(location: searchRangeLocation, length: content.length - searchRangeLocation)

        // Wrap around if search range is empty or at the end
        let needsWrap = searchRange.length == 0
        if needsWrap {
            searchRange = NSRange(location: 0, length: content.length) // Search entire document
        }

        // Perform the search forward
        let foundRange = content.range(of: searchString, options: [], range: searchRange)

        if foundRange.location != NSNotFound {
            textView.selectedRange = foundRange
            textView.scrollRangeToVisible(foundRange)
            print("Found next at: \(foundRange)")
            if needsWrap { print("(Wrapped)") }
        } else if !needsWrap {
            // If not found in the forward range, try searching from the beginning up to original start point
            searchRange = NSRange(location: 0, length: currentRange.location) // Search before current selection
            let wrappedRange = content.range(of: searchString, options: [], range: searchRange)
            if wrappedRange.location != NSNotFound {
                 textView.selectedRange = wrappedRange
                 textView.scrollRangeToVisible(wrappedRange)
                 print("Found next (wrapped) at: \(wrappedRange)")
            } else {
                 // Not found anywhere
                 NSSound.beep() // Indicate not found
                 print("Not found next.")
            }
        } else {
             // Wrapped search already failed
             NSSound.beep()
             print("Not found next (after wrap attempt).")
        }
    }

    func findPrevious() {
        print("Action: Find Previous")
         guard let textView = nsTextView,
               let content = textView.string as NSString?,
               !documentState.findText.isEmpty else { return }

        let searchString = documentState.findText
        let currentRange = textView.selectedRange()
        // Search range is from document start up to the start of the current selection
        var searchRange = NSRange(location: 0, length: currentRange.location)

        // Wrap around if search range is empty (cursor at beginning)
        let needsWrap = searchRange.length == 0
         if needsWrap && content.length > 0 {
             searchRange = NSRange(location: 0, length: content.length) // Search entire document backwards
         }

        // Perform the search backward
        let foundRange = content.range(of: searchString, options: .backwards, range: searchRange)

        if foundRange.location != NSNotFound {
            textView.selectedRange = foundRange
            textView.scrollRangeToVisible(foundRange)
            print("Found previous at: \(foundRange)")
             if needsWrap { print("(Wrapped)") }
        } else if !needsWrap {
             // If not found in the backward range, try searching from the end down to original end point
             let wrapStartLocation = currentRange.location + currentRange.length
             if wrapStartLocation < content.length { // Only wrap if there's text after current selection
                  searchRange = NSRange(location: wrapStartLocation, length: content.length - wrapStartLocation) // Search after current selection
                  let wrappedRange = content.range(of: searchString, options: .backwards, range: searchRange)
                  if wrappedRange.location != NSNotFound {
                      textView.selectedRange = wrappedRange
                      textView.scrollRangeToVisible(wrappedRange)
                      print("Found previous (wrapped) at: \(wrappedRange)")
                  } else {
                      // Not found anywhere
                      NSSound.beep() // Indicate not found
                      print("Not found previous.")
                  }
             } else {
                 // Nothing to wrap to after selection
                  NSSound.beep()
                  print("Not found previous (nothing after selection).")
             }
        } else {
             // Wrapped search already failed
             NSSound.beep()
             print("Not found previous (after wrap attempt).")
        }
    }

    func replace() {
        print("Action: Replace")
         guard let textView = nsTextView,
               let content = textView.string as NSString?,
               !documentState.findText.isEmpty else {
                   NSSound.beep()
                   return
               }

        let currentRange = textView.selectedRange()
        let findString = documentState.findText
        let replaceString = documentState.replaceText

        // Check if the currently selected text actually matches the find string
        if currentRange.length > 0 && content.substring(with: currentRange) == findString {
             if textView.shouldChangeText(in: currentRange, replacementString: replaceString) {
                 textView.replaceCharacters(in: currentRange, with: replaceString)
                 textView.didChangeText() // Notify that text changed
                 print("Replaced at: \(currentRange)")
             } else {
                 print("Replace vetoed by shouldChangeText")
                 NSSound.beep()
             }
        } else {
             print("Selection does not match find string or is empty, finding next instead.")
            // If nothing is selected, or selection doesn't match, just find the next one.
            // User might have clicked elsewhere.
        }

        // Always find the next occurrence after a replace action
        findNext()
    }

    func replaceAll() {
        print("Action: Replace All")
         guard let textView = nsTextView,
               let textStorage = textView.textStorage, // Use TextStorage for modification
               let content = textView.string as NSString?, // Still need NSString for range finding
               !documentState.findText.isEmpty else {
                    NSSound.beep()
                    return
                }

        let findString = documentState.findText
        let replaceString = documentState.replaceText
        var replacementCount = 0

        // Use TextStorage for efficient modification and undo grouping
        textStorage.beginEditing()
        var searchRange = NSRange(location: 0, length: content.length) // Initial full range for NSString search
        var currentContentLength = content.length // Track length for range adjustments

        // Iterate backwards using NSString range finding
        while searchRange.length > 0 {
            // Use currentContentLength for the search range as textStorage length changes
             let effectiveSearchRange = NSRange(location: 0, length: currentContentLength)
            
            // Find range in the potentially modified content (re-fetch string if needed, but NSString should be okay if only length changes)
            let currentStringForSearch = textStorage.string as NSString
             let foundRange = currentStringForSearch.range(of: findString, options: [.backwards], range: effectiveSearchRange)
            
            if foundRange.location != NSNotFound {
                if textView.shouldChangeText(in: foundRange, replacementString: replaceString) {
                    // Replace using TextStorage method
                    textStorage.replaceCharacters(in: foundRange, with: replaceString)
                    replacementCount += 1
                     print("Replaced all instance at: \(foundRange)")
                    // Update content length after modification
                    currentContentLength = textStorage.length
                } else {
                     print("Replace All vetoed for range: \(foundRange)")
                }
                 // Adjust search range length for the next iteration (search before the found range)
                 // We use foundRange.location because we search backwards
                 currentContentLength = foundRange.location 
                 if currentContentLength == 0 { break } // Stop if we reached the beginning
                 
            } else {
                break // No more occurrences found in the remaining range
            } 
        }
        textStorage.endEditing() // Consolidate undo action

        if replacementCount > 0 {
            textView.didChangeText() // Notify change after all replacements
            print("Replaced \(replacementCount) occurrence(s).")
            // Optionally show an alert or status update
        } else {
            print("No occurrences found to replace.")
            NSSound.beep()
        }
         // Reset selection after replace all? Maybe to the beginning?
         textView.selectedRange = NSRange(location: 0, length: 0)
         updateCursorPosition(textView: textView) // Update display
    }

    // --- Coordinator and Delegate ---
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ContentView

        init(_ parent: ContentView) {
            self.parent = parent
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.updateCursorPosition(textView: textView)
        }
    }

    func updateCursorPosition(textView: NSTextView) {
        guard let content = textView.string as NSString? else { return }
        let selectedRange = textView.selectedRange()
        let insertionPoint = selectedRange.location

        var line = 1
        var column = 1

        if insertionPoint <= content.length {
            var lineStartIndex = 0
            for i in 0..<insertionPoint {
                if content.character(at: i) == 10 { // \n
                    line += 1
                    lineStartIndex = i + 1
                }
            }
            column = insertionPoint - lineStartIndex + 1
        } else {
            let endPoint = content.length
            var lineStartIndex = 0
            for i in 0..<endPoint {
                if content.character(at: i) == 10 { // \n
                    line += 1
                    lineStartIndex = i + 1
                }
            }
            column = endPoint - lineStartIndex + 1
        }
        
        DispatchQueue.main.async {
            self.cursorPosition = (line, column)
        }
    }
}

extension NSView {
    func findSubview<T: NSView>(ofType type: T.Type) -> T? {
        if let typedSelf = self as? T {
            return typedSelf
        }
        for subview in subviews {
            if let found = subview.findSubview(ofType: type) {
                return found
            }
        }
        return nil
    }
}

#Preview {
    ContentView()
}
