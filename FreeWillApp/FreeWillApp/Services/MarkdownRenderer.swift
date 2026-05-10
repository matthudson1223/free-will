import Foundation

enum MarkdownRenderer {
    static func render(_ text: String) -> AttributedString {
        return (try? AttributedString(markdown: text))
            ?? AttributedString(text)
    }
}
