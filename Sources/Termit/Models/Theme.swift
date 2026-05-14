import Foundation
import SwiftUI

struct Theme: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let background: String
    let foreground: String
    let cursor: String
    let selection: String
    let palette: [String]
    let isDark: Bool

    var backgroundColor: Color { Color(hex: background) }
    var foregroundColor: Color { Color(hex: foreground) }
    var cursorColor: Color { Color(hex: cursor) }
    var selectionColor: Color { Color(hex: selection) }

    func ansiColor(_ index: Int) -> Color {
        guard palette.indices.contains(index) else { return foregroundColor }
        return Color(hex: palette[index])
    }
}

@MainActor
final class ThemeStore: ObservableObject {
    @Published var selectedID: String = "solarized-dark"
    @Published private(set) var themes: [Theme] = Theme.builtIn

    var current: Theme {
        themes.first(where: { $0.id == selectedID }) ?? themes[0]
    }

    var colorScheme: ColorScheme? {
        current.isDark ? .dark : .light
    }
}

extension Theme {
    static let builtIn: [Theme] = [
        Theme(
            id: "solarized-dark",
            name: "Solarized Dark",
            background: "#002b36",
            foreground: "#839496",
            cursor: "#93a1a1",
            selection: "#073642",
            palette: ["#073642","#dc322f","#859900","#b58900","#268bd2","#d33682","#2aa198","#eee8d5",
                      "#002b36","#cb4b16","#586e75","#657b83","#839496","#6c71c4","#93a1a1","#fdf6e3"],
            isDark: true
        ),
        Theme(
            id: "dracula",
            name: "Dracula",
            background: "#282a36",
            foreground: "#f8f8f2",
            cursor: "#f8f8f2",
            selection: "#44475a",
            palette: ["#000000","#ff5555","#50fa7b","#f1fa8c","#bd93f9","#ff79c6","#8be9fd","#bfbfbf",
                      "#4d4d4d","#ff6e67","#5af78e","#f4f99d","#caa9fa","#ff92d0","#9aedfe","#e6e6e6"],
            isDark: true
        ),
        Theme(
            id: "nord",
            name: "Nord",
            background: "#2e3440",
            foreground: "#d8dee9",
            cursor: "#d8dee9",
            selection: "#434c5e",
            palette: ["#3b4252","#bf616a","#a3be8c","#ebcb8b","#81a1c1","#b48ead","#88c0d0","#e5e9f0",
                      "#4c566a","#bf616a","#a3be8c","#ebcb8b","#81a1c1","#b48ead","#8fbcbb","#eceff4"],
            isDark: true
        ),
        Theme(
            id: "tomorrow-night",
            name: "Tomorrow Night",
            background: "#1d1f21",
            foreground: "#c5c8c6",
            cursor: "#c5c8c6",
            selection: "#373b41",
            palette: ["#1d1f21","#cc6666","#b5bd68","#f0c674","#81a2be","#b294bb","#8abeb7","#c5c8c6",
                      "#969896","#cc6666","#b5bd68","#f0c674","#81a2be","#b294bb","#8abeb7","#ffffff"],
            isDark: true
        ),
        Theme(
            id: "catppuccin-mocha",
            name: "Catppuccin Mocha",
            background: "#1e1e2e",
            foreground: "#cdd6f4",
            cursor: "#f5e0dc",
            selection: "#585b70",
            palette: ["#45475a","#f38ba8","#a6e3a1","#f9e2af","#89b4fa","#f5c2e7","#94e2d5","#bac2de",
                      "#585b70","#f38ba8","#a6e3a1","#f9e2af","#89b4fa","#f5c2e7","#94e2d5","#a6adc8"],
            isDark: true
        ),
    ]
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.hasPrefix("#") ? String(hex.dropFirst()) : hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xff) / 255.0
        let g = Double((rgb >> 8) & 0xff) / 255.0
        let b = Double(rgb & 0xff) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
