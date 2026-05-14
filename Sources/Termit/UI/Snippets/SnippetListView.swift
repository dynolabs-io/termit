import SwiftUI

struct SnippetListView: View {
    @EnvironmentObject var snippetStore: SnippetStore
    @State private var editing: Snippet?
    @State private var showEditor = false

    var body: some View {
        List {
            ForEach(snippetStore.snippets) { snippet in
                VStack(alignment: .leading, spacing: 4) {
                    Text(snippet.name).font(.headline)
                    Text(snippet.command)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                    if !snippet.tagsScope.isEmpty {
                        Text("Tags: \(snippet.tagsScope.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        snippetStore.delete(snippet)
                    } label: { Label("Delete", systemImage: "trash") }
                    Button {
                        editing = snippet
                        showEditor = true
                    } label: { Label("Edit", systemImage: "pencil") }
                }
            }
        }
        .navigationTitle("Snippets")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { editing = nil; showEditor = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showEditor) {
            SnippetEditView(snippet: editing) { saved in
                if snippetStore.snippets.contains(where: { $0.id == saved.id }) {
                    snippetStore.update(saved)
                } else {
                    snippetStore.add(saved)
                }
                showEditor = false
            }
        }
    }
}

struct SnippetEditView: View {
    let snippet: Snippet?
    let onSave: (Snippet) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var command = ""
    @State private var tagsRaw = ""
    @State private var requireConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextEditor(text: $command)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 100)
                TextField("Tag scope (comma-separated, empty = all hosts)", text: $tagsRaw)
                    .textInputAutocapitalization(.never)
                Toggle("Confirm before running", isOn: $requireConfirmation)
                Section("Variables you can use") {
                    Text("$HOST, $USER, $ALIAS, $PORT").font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(snippet == nil ? "New Snippet" : "Edit Snippet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let tags = tagsRaw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        onSave(Snippet(
                            id: snippet?.id ?? UUID(),
                            name: name,
                            command: command,
                            tagsScope: tags,
                            requireConfirmation: requireConfirmation
                        ))
                    }
                    .disabled(name.isEmpty || command.isEmpty)
                }
            }
            .onAppear {
                guard let snippet = snippet else { return }
                name = snippet.name
                command = snippet.command
                tagsRaw = snippet.tagsScope.joined(separator: ", ")
                requireConfirmation = snippet.requireConfirmation
            }
        }
    }
}
