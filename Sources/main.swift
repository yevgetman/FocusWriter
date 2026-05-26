import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct FocusWriterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            WriterView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .pasteboard) {
                Button("Cut") { NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil) }
                    .keyboardShortcut("x")
                Button("Copy") { NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil) }
                    .keyboardShortcut("c")
                Button("Paste") { NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil) }
                    .keyboardShortcut("v")
                Button("Select All") { NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil) }
                    .keyboardShortcut("a")
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { NSApp.sendAction(Selector(("undo:")), to: nil, from: nil) }
                    .keyboardShortcut("z")
                Button("Redo") { NSApp.sendAction(Selector(("redo:")), to: nil, from: nil) }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApp.windows.first {
            window.setContentSize(NSSize(width: 900, height: 700))
            window.center()
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

class DocumentState: ObservableObject {
    @Published var text = ""
    @Published var currentURL: URL? = nil
    @Published var savedText = ""

    var hasUnsavedChanges: Bool { text != savedText }

    func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            loadFile(url)
        }
    }

    func loadFile(_ url: URL) {
        if let content = try? String(contentsOf: url, encoding: .utf8) {
            text = content
            savedText = content
            currentURL = url
            NSApp.windows.first?.title = url.lastPathComponent
        }
    }

    func save() {
        if let url = currentURL {
            try? text.write(to: url, atomically: true, encoding: .utf8)
            savedText = text
        } else {
            saveAs()
        }
    }

    func saveAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = currentURL?.lastPathComponent ?? "untitled.txt"
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            try? text.write(to: url, atomically: true, encoding: .utf8)
            savedText = text
            currentURL = url
            NSApp.windows.first?.title = url.lastPathComponent
        }
    }

    func newFile() {
        text = ""
        savedText = ""
        currentURL = nil
        NSApp.windows.first?.title = "FocusWriter"
    }
}

struct WriterView: View {
    @StateObject private var doc = DocumentState()

    var body: some View {
        ZStack {
            Color(nsColor: NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1))
                .ignoresSafeArea()

            FocusTextEditor(text: $doc.text)
                .padding(.horizontal, 80)
                .padding(.vertical, 40)
        }
        .frame(minWidth: 600, minHeight: 400)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if doc.hasUnsavedChanges && !doc.text.isEmpty {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .help("Unsaved changes")
                }
            }
        }
        .background(
            Group {
                Button("") { doc.save() }
                    .keyboardShortcut("s")
                    .hidden()
                Button("") { doc.openFile() }
                    .keyboardShortcut("o")
                    .hidden()
                Button("") { doc.newFile() }
                    .keyboardShortcut("n")
                    .hidden()
                Button("") { doc.saveAs() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .hidden()
            }
        )
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            if let provider = providers.first {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async { doc.loadFile(url) }
                    }
                }
            }
            return true
        }
    }
}

struct FocusTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        textView.insertionPointColor = NSColor(white: 0.65, alpha: 1)
        textView.textColor = NSColor(white: 0.65, alpha: 1)
        textView.font = NSFont(name: "Georgia", size: 18) ?? NSFont.systemFont(ofSize: 18)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 0, height: 10)
        textView.typingAttributes = [
            .foregroundColor: NSColor(white: 0.65, alpha: 1),
            .font: NSFont(name: "Georgia", size: 18) ?? NSFont.systemFont(ofSize: 18)
        ]

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes[.paragraphStyle] = paragraphStyle

        scrollView.hasVerticalScroller = true
        scrollView.scrollerStyle = .overlay
        scrollView.backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        scrollView.drawsBackground = true
        scrollView.scrollerKnobStyle = .light

        textView.delegate = context.coordinator
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: FocusTextEditor
        init(_ parent: FocusTextEditor) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }
    }
}
