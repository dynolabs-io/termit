import XCTest
@testable import Termit

final class VT100ParserTests: XCTestCase {
    final class Sink: TerminalParserDelegate {
        var chars: [Character] = []
        var controls: [VT100Parser.Control] = []
        var csis: [VT100Parser.CSI] = []
        var oscs: [VT100Parser.OSC] = []
        func parser(_ parser: VT100Parser, didReceive char: Character) { chars.append(char) }
        func parser(_ parser: VT100Parser, didExecute control: VT100Parser.Control) { controls.append(control) }
        func parser(_ parser: VT100Parser, didApply csi: VT100Parser.CSI) { csis.append(csi) }
        func parser(_ parser: VT100Parser, didApply osc: VT100Parser.OSC) { oscs.append(osc) }
    }

    func testPlainText() {
        let p = VT100Parser(); let s = Sink(); p.delegate = s
        p.feed(Data("hello".utf8))
        XCTAssertEqual(s.chars.map(String.init).joined(), "hello")
    }

    func testSGRReset() {
        let p = VT100Parser(); let s = Sink(); p.delegate = s
        p.feed(Data("\u{1b}[0m".utf8))
        XCTAssertEqual(s.csis.count, 1)
        XCTAssertEqual(s.csis.first?.finalChar, "m")
    }

    func testOSC52() {
        let p = VT100Parser(); let s = Sink(); p.delegate = s
        p.feed(Data("\u{1b}]52;c;aGVsbG8=\u{07}".utf8))
        XCTAssertEqual(s.oscs.count, 1)
        XCTAssertEqual(s.oscs.first?.code, 52)
    }
}
