import Foundation
import SwiftUI

struct TermCell: Hashable {
    var character: Character
    var fgIndex: Int
    var bgIndex: Int
    var bold: Bool
    var italic: Bool
    var underline: Bool
    var reverse: Bool
}

final class TerminalBuffer {
    private(set) var rows: Int
    private(set) var cols: Int
    private(set) var cells: [[TermCell]]
    private(set) var cursorRow: Int = 0
    private(set) var cursorCol: Int = 0
    private(set) var fg: Int = 7
    private(set) var bg: Int = 0
    private(set) var attrBold = false
    private(set) var attrItalic = false
    private(set) var attrUnderline = false
    private(set) var attrReverse = false
    private(set) var scrollbackLines: [[TermCell]] = []

    init(rows: Int = 24, cols: Int = 80) {
        self.rows = rows
        self.cols = cols
        self.cells = Array(
            repeating: Array(repeating: TermCell(character: " ", fgIndex: 7, bgIndex: 0, bold: false, italic: false, underline: false, reverse: false), count: cols),
            count: rows
        )
    }

    func resize(rows: Int, cols: Int) {
        guard rows > 0 && cols > 0 else { return }
        var newCells: [[TermCell]] = []
        for r in 0..<rows {
            if r < self.rows {
                var row = self.cells[r]
                if row.count < cols {
                    row.append(contentsOf: Array(
                        repeating: TermCell(character: " ", fgIndex: 7, bgIndex: 0, bold: false, italic: false, underline: false, reverse: false),
                        count: cols - row.count
                    ))
                } else if row.count > cols {
                    row = Array(row.prefix(cols))
                }
                newCells.append(row)
            } else {
                newCells.append(Array(
                    repeating: TermCell(character: " ", fgIndex: 7, bgIndex: 0, bold: false, italic: false, underline: false, reverse: false),
                    count: cols
                ))
            }
        }
        self.cells = newCells
        self.rows = rows
        self.cols = cols
        self.cursorRow = min(cursorRow, rows - 1)
        self.cursorCol = min(cursorCol, cols - 1)
    }

    func write(_ c: Character) {
        if cursorCol >= cols { newline() }
        cells[cursorRow][cursorCol] = TermCell(
            character: c,
            fgIndex: fg, bgIndex: bg,
            bold: attrBold, italic: attrItalic,
            underline: attrUnderline, reverse: attrReverse
        )
        cursorCol += 1
    }

    func newline() {
        cursorCol = 0
        cursorRow += 1
        if cursorRow >= rows {
            scrollbackLines.append(cells.removeFirst())
            if scrollbackLines.count > 10_000 { scrollbackLines.removeFirst() }
            cells.append(Array(
                repeating: TermCell(character: " ", fgIndex: 7, bgIndex: 0, bold: false, italic: false, underline: false, reverse: false),
                count: cols
            ))
            cursorRow = rows - 1
        }
    }

    func carriageReturn() { cursorCol = 0 }
    func backspace() { if cursorCol > 0 { cursorCol -= 1 } }

    func setSGR(_ params: [Int]) {
        let actual = params.isEmpty ? [0] : params
        var i = 0
        while i < actual.count {
            let p = actual[i]
            switch p {
            case 0:
                fg = 7; bg = 0
                attrBold = false; attrItalic = false; attrUnderline = false; attrReverse = false
            case 1: attrBold = true
            case 3: attrItalic = true
            case 4: attrUnderline = true
            case 7: attrReverse = true
            case 22: attrBold = false
            case 23: attrItalic = false
            case 24: attrUnderline = false
            case 27: attrReverse = false
            case 30...37: fg = p - 30
            case 40...47: bg = p - 40
            case 90...97: fg = p - 82
            case 100...107: bg = p - 92
            case 38:
                if i + 2 < actual.count, actual[i+1] == 5 {
                    fg = actual[i+2]
                    i += 2
                }
            case 48:
                if i + 2 < actual.count, actual[i+1] == 5 {
                    bg = actual[i+2]
                    i += 2
                }
            default: break
            }
            i += 1
        }
    }

    func moveCursor(row: Int, col: Int) {
        cursorRow = max(0, min(rows - 1, row))
        cursorCol = max(0, min(cols - 1, col))
    }

    func clearScreen() {
        cells = Array(
            repeating: Array(
                repeating: TermCell(character: " ", fgIndex: fg, bgIndex: bg, bold: false, italic: false, underline: false, reverse: false),
                count: cols
            ),
            count: rows
        )
        cursorRow = 0; cursorCol = 0
    }
}
