import Foundation
import SwiftUI

extension String {
    /// Strips HTML tags and decodes HTML entities, returning plain text
    var strippedHTML: String {
        // Remove HTML tags
        var result = self.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        // Decode common HTML entities
        let entities: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
            ("&nbsp;", " "),
            ("&#x27;", "'"),
            ("&#x2F;", "/"),
            ("&mdash;", "—"),
            ("&ndash;", "–"),
            ("&hellip;", "…"),
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        // Collapse multiple whitespace/newlines into single space
        result = result.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        return result
    }
}

/// A view that renders text with tappable URLs
struct LinkedText: View {
    let text: String
    let font: Font

    init(_ text: String, font: Font = .body) {
        self.text = text
        self.font = font
    }

    private static let urlPattern = try! NSRegularExpression(
        pattern: "https?://[^\\s<>\"']+",
        options: .caseInsensitive
    )

    /// Split text into segments: plain strings and URLs
    private var segments: [(String, URL?)] {
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = Self.urlPattern.matches(in: text, range: range)

        var result: [(String, URL?)] = []
        var lastEnd = 0

        for match in matches {
            let matchRange = match.range
            // Plain text before this URL
            if matchRange.location > lastEnd {
                let plain = nsText.substring(with: NSRange(location: lastEnd, length: matchRange.location - lastEnd))
                if !plain.isEmpty { result.append((plain, nil)) }
            }
            // The URL itself
            let urlStr = nsText.substring(with: matchRange)
            result.append((urlStr, URL(string: urlStr)))
            lastEnd = matchRange.location + matchRange.length
        }

        // Trailing plain text
        if lastEnd < nsText.length {
            let trailing = nsText.substring(from: lastEnd)
            if !trailing.isEmpty { result.append((trailing, nil)) }
        }

        if result.isEmpty { result.append((text, nil)) }
        return result
    }

    var body: some View {
        segments.reduce(Text("")) { result, segment in
            if let url = segment.1 {
                return result + Text(.init("[\(segment.0)](\(url.absoluteString))"))
                    .foregroundColor(.brandBlue)
                    .underline()
            } else {
                return result + Text(segment.0)
            }
        }
        .font(font)
    }
}
