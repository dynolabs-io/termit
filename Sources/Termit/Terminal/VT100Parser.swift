import Foundation

protocol TerminalParserDelegate: AnyObject {
    func parser(_ parser: VT100Parser, didReceive char: Character)
    func parser(_ parser: VT100Parser, didExecute control: VT100Parser.Control)
    func parser(_ parser: VT100Parser, didApply csi: VT100Parser.CSI)
    func parser(_ parser: VT100Parser, didApply osc: VT100Parser.OSC)
}

final class VT100Parser {
    enum State {
        case ground
        case escape
        case csiEntry
        case csiParam
        case oscString
    }

    enum Control {
        case bell, backspace, tab, lineFeed, carriageReturn, formFeed
    }

    struct CSI {
        let intermediate: [Character]
        let params: [Int]
        let finalChar: Character
    }

    struct OSC {
        let code: Int
        let payload: String
    }

    weak var delegate: TerminalParserDelegate?
    private var state: State = .ground
    private var buffer: String = ""
    private var params: [Int] = []
    private var paramAccumulator: String = ""
    private var oscBuffer: String = ""

    func feed(_ data: Data) {
        guard let s = String(data: data, encoding: .utf8) else { return }
        for c in s { step(c) }
    }

    private func step(_ c: Character) {
        switch state {
        case .ground:
            ground(c)
        case .escape:
            escape(c)
        case .csiEntry, .csiParam:
            csi(c)
        case .oscString:
            osc(c)
        }
    }

    private func ground(_ c: Character) {
        switch c {
        case "\u{07}": delegate?.parser(self, didExecute: .bell)
        case "\u{08}": delegate?.parser(self, didExecute: .backspace)
        case "\u{09}": delegate?.parser(self, didExecute: .tab)
        case "\u{0a}": delegate?.parser(self, didExecute: .lineFeed)
        case "\u{0c}": delegate?.parser(self, didExecute: .formFeed)
        case "\u{0d}": delegate?.parser(self, didExecute: .carriageReturn)
        case "\u{1b}": state = .escape
        default: delegate?.parser(self, didReceive: c)
        }
    }

    private func escape(_ c: Character) {
        switch c {
        case "[": state = .csiEntry; params.removeAll(); paramAccumulator = ""
        case "]": state = .oscString; oscBuffer = ""
        default: state = .ground
        }
    }

    private func csi(_ c: Character) {
        if c.isNumber {
            paramAccumulator.append(c)
            state = .csiParam
        } else if c == ";" {
            params.append(Int(paramAccumulator) ?? 0)
            paramAccumulator = ""
        } else {
            if !paramAccumulator.isEmpty {
                params.append(Int(paramAccumulator) ?? 0)
            }
            delegate?.parser(self, didApply: CSI(intermediate: [], params: params, finalChar: c))
            state = .ground
        }
    }

    private func osc(_ c: Character) {
        if c == "\u{07}" || c == "\u{9c}" {
            if let semi = oscBuffer.firstIndex(of: ";") {
                let code = Int(oscBuffer[..<semi]) ?? 0
                let payload = String(oscBuffer[oscBuffer.index(after: semi)...])
                delegate?.parser(self, didApply: OSC(code: code, payload: payload))
            }
            state = .ground
        } else {
            oscBuffer.append(c)
        }
    }
}
