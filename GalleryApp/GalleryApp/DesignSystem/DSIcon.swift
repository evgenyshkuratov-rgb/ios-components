import UIKit

enum DSIcon {

    static func named(_ name: String, size: CGFloat = 24) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "svg"),
              let svgString = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        let viewBox = parseViewBox(svgString) ?? CGRect(x: 0, y: 0, width: 24, height: 24)
        let paths = parsePaths(svgString)

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let scaleX = size / viewBox.width
            let scaleY = size / viewBox.height
            context.cgContext.translateBy(x: -viewBox.origin.x * scaleX,
                                          y: -viewBox.origin.y * scaleY)
            context.cgContext.scaleBy(x: scaleX, y: scaleY)

            UIColor.black.setFill()
            for (bezier, _) in paths {
                bezier.fill()
            }
        }

        return image.withRenderingMode(.alwaysTemplate)
    }

    // MARK: - SVG Parsing

    private static func parseViewBox(_ svg: String) -> CGRect? {
        guard let range = svg.range(of: "viewBox=\""),
              let endRange = svg[range.upperBound...].range(of: "\"") else {
            return nil
        }
        let parts = svg[range.upperBound..<endRange.lowerBound]
            .split(separator: " ")
            .compactMap { Double($0) }
        guard parts.count == 4 else { return nil }
        return CGRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
    }

    private static func parsePaths(_ svg: String) -> [(UIBezierPath, CAShapeLayerFillRule)] {
        var results: [(UIBezierPath, CAShapeLayerFillRule)] = []
        var searchStart = svg.startIndex

        while let pathStart = svg[searchStart...].range(of: "<path") {
            guard let tagEnd = svg[pathStart.lowerBound...].range(of: "/>") ??
                               svg[pathStart.lowerBound...].range(of: ">") else { break }

            let tag = String(svg[pathStart.lowerBound..<tagEnd.upperBound])

            if let d = extractAttribute("d", from: tag) {
                let fillRule: CAShapeLayerFillRule =
                    extractAttribute("fill-rule", from: tag) == "evenodd" ? .evenOdd : .nonZero
                let bezier = SVGPathParser.parse(d, fillRule: fillRule)
                results.append((bezier, fillRule))
            }

            searchStart = tagEnd.upperBound
        }
        return results
    }

    private static func extractAttribute(_ name: String, from tag: String) -> String? {
        let pattern = name + "=\""
        guard let start = tag.range(of: pattern) else { return nil }
        guard let end = tag[start.upperBound...].range(of: "\"") else { return nil }
        return String(tag[start.upperBound..<end.lowerBound])
    }
}
