//
//  freewriteApp.swift
//  freewrite
//
//  Created by thorfinn on 2/14/25.
//

import SwiftUI

@main
struct freewriteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var documentState = DocumentState()
    
    init() {
        // Register Lato font
        if let fontURL = Bundle.main.url(forResource: "Lato-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
     
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(documentState)
        }
        .defaultSize(width: 1100, height: 600)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    documentState.newDocument()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .newItem) {
                Button("Open...") {
                    documentState.openDocument()
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Save") {
                    documentState.saveDocument()
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!documentState.hasUnsavedChanges && documentState.fileURL != nil)
                
                Button("Save As...") {
                    documentState.saveDocumentAs()
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])
            }
            
            CommandGroup(replacing: .undoRedo) {
                EmptyView()
            }
            
            CommandGroup(replacing: .pasteboard) {
                 EmptyView()
            }

            CommandMenu("Edit") {
                 Button("Find") {
                     documentState.showFindReplacePanel = true // Show the panel
                     // Optionally clear replace text if just finding?
                 }
                 .keyboardShortcut("f", modifiers: .command)
                 
                 Button("Find and Replace") {
                     documentState.showFindReplacePanel = true // Show the panel
                 }
                 .keyboardShortcut("f", modifiers: [.command, .option])
            }
            
            CommandMenu("Tools") { // Tools Menu
                 Button("Statistics") {
                    documentState.calculateStatistics()
                 }
                 // No default shortcut, user can add via System Settings
            }
        }
    }
}

// Add AppDelegate to handle window configuration
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            // Ensure window starts in windowed mode
            if window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
            
            // Center the window on the screen
            window.center()
        }
    }
} 