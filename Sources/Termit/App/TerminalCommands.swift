import SwiftUI

struct TerminalCommands: Commands {
    var body: some Commands {
        CommandMenu("Session") {
            Button("New Tab") {}.keyboardShortcut("t", modifiers: .command)
            Button("Close Tab") {}.keyboardShortcut("w", modifiers: .command)
            Divider()
            Button("Previous Tab") {}.keyboardShortcut("[", modifiers: [.command, .shift])
            Button("Next Tab") {}.keyboardShortcut("]", modifiers: [.command, .shift])
            Divider()
            Button("Send Ctrl-C") {}.keyboardShortcut("c", modifiers: .control)
            Button("Send Ctrl-D") {}.keyboardShortcut("d", modifiers: .control)
            Button("Send Escape") {}.keyboardShortcut(.escape, modifiers: [])
        }
        CommandMenu("Connection") {
            Button("Disconnect") {}.keyboardShortcut(".", modifiers: .command)
            Button("Reconnect") {}.keyboardShortcut("r", modifiers: [.command, .shift])
        }
        CommandMenu("Window") {
            Button("New Window") {}.keyboardShortcut("n", modifiers: .command)
        }
    }
}
