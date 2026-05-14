import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class TerminalEngine: ObservableObject, TerminalParserDelegate {
    @Published private(set) var buffer: TerminalBuffer
    private let parser = VT100Parser()
    var onSend: ((Data) -> Void)?

    init(rows: Int = 24, cols: Int = 80) {
        self.buffer = TerminalBuffer(rows: rows, cols: cols)
        parser.delegate = self
    }

    func feed(_ data: Data) {
        parser.feed(data)
        objectWillChange.send()
    }

    func resize(rows: Int, cols: Int) {
        buffer.resize(rows: rows, cols: cols)
    }

    func sendInput(_ text: String) {
        onSend?(Data(text.utf8))
    }

    func parser(_ parser: VT100Parser, didReceive char: Character) {
        buffer.write(char)
    }

    func parser(_ parser: VT100Parser, didExecute control: VT100Parser.Control) {
        switch control {
        case .lineFeed: buffer.newline()
        case .carriageReturn: buffer.carriageReturn()
        case .backspace: buffer.backspace()
        case .bell, .tab, .formFeed: break
        }
    }

    func parser(_ parser: VT100Parser, didApply csi: VT100Parser.CSI) {
        switch csi.finalChar {
        case "m": buffer.setSGR(csi.params)
        case "H", "f":
            let row = (csi.params.first ?? 1) - 1
            let col = (csi.params.count > 1 ? csi.params[1] : 1) - 1
            buffer.moveCursor(row: row, col: col)
        case "J":
            if (csi.params.first ?? 0) == 2 { buffer.clearScreen() }
        default: break
        }
    }

    func parser(_ parser: VT100Parser, didApply osc: VT100Parser.OSC) {
        if osc.code == 52 { handleOSC52(osc.payload) }
    }

    private func handleOSC52(_ payload: String) {
        let parts = payload.split(separator: ";")
        guard parts.count == 2 else { return }
        if let data = Data(base64Encoded: String(parts[1])),
           let text = String(data: data, encoding: .utf8) {
            #if canImport(UIKit)
            UIPasteboard.general.string = text
            #endif
        }
    }
}
