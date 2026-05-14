import SwiftUI

struct TerminalView: View {
    @ObservedObject var engine: TerminalEngine
    @EnvironmentObject var themeStore: ThemeStore
    let host: Host
    @FocusState private var inputFocused: Bool
    @State private var input: String = ""

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(engine.buffer.cells.enumerated()), id: \.offset) { idx, row in
                                Text(rowString(row))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(themeStore.current.foregroundColor)
                                    .id(idx)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .onChange(of: engine.buffer.cursorRow) { _, newRow in
                        withAnimation(.linear(duration: 0.05)) {
                            proxy.scrollTo(newRow, anchor: .bottom)
                        }
                    }
                }
                inputBar
            }
        }
        .background(themeStore.current.backgroundColor)
    }

    private var inputBar: some View {
        HStack {
            TextField("", text: $input)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(themeStore.current.foregroundColor)
                .focused($inputFocused)
                .onSubmit {
                    engine.sendInput(input + "\n")
                    input = ""
                }
            Button(action: sendCtrlC) { Image(systemName: "control") }
                .keyboardShortcut("c", modifiers: .control)
            Button(action: sendTab) { Image(systemName: "arrow.right.to.line") }
        }
        .padding(8)
        .background(.thinMaterial)
    }

    private func sendCtrlC() {
        engine.sendInput("\u{03}")
    }

    private func sendTab() {
        engine.sendInput("\t")
    }

    private func rowString(_ row: [TermCell]) -> String {
        String(row.map { $0.character })
    }
}
