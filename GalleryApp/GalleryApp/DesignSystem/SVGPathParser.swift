import UIKit

enum SVGPathParser {

    static func parse(_ d: String, fillRule: CAShapeLayerFillRule = .nonZero) -> UIBezierPath {
        let path = UIBezierPath()
        let tokens = tokenize(d)
        var i = 0
        var currentCommand: Character = "M"

        while i < tokens.count {
            let token = tokens[i]
            if token.count == 1, token.first!.isLetter {
                currentCommand = token.first!
                i += 1
            }

            switch currentCommand {
            case "M":
                let x = number(tokens, &i), y = number(tokens, &i)
                path.move(to: CGPoint(x: x, y: y))
                currentCommand = "L"
            case "m":
                let dx = number(tokens, &i), dy = number(tokens, &i)
                path.move(to: CGPoint(x: path.currentPoint.x + dx, y: path.currentPoint.y + dy))
                currentCommand = "l"
            case "L":
                let x = number(tokens, &i), y = number(tokens, &i)
                path.addLine(to: CGPoint(x: x, y: y))
            case "l":
                let dx = number(tokens, &i), dy = number(tokens, &i)
                path.addLine(to: CGPoint(x: path.currentPoint.x + dx, y: path.currentPoint.y + dy))
            case "H":
                let x = number(tokens, &i)
                path.addLine(to: CGPoint(x: x, y: path.currentPoint.y))
            case "h":
                let dx = number(tokens, &i)
                path.addLine(to: CGPoint(x: path.currentPoint.x + dx, y: path.currentPoint.y))
            case "V":
                let y = number(tokens, &i)
                path.addLine(to: CGPoint(x: path.currentPoint.x, y: y))
            case "v":
                let dy = number(tokens, &i)
                path.addLine(to: CGPoint(x: path.currentPoint.x, y: path.currentPoint.y + dy))
            case "C":
                let x1 = number(tokens, &i), y1 = number(tokens, &i)
                let x2 = number(tokens, &i), y2 = number(tokens, &i)
                let x = number(tokens, &i), y = number(tokens, &i)
                path.addCurve(to: CGPoint(x: x, y: y),
                              controlPoint1: CGPoint(x: x1, y: y1),
                              controlPoint2: CGPoint(x: x2, y: y2))
            case "c":
                let cp = path.currentPoint
                let x1 = number(tokens, &i), y1 = number(tokens, &i)
                let x2 = number(tokens, &i), y2 = number(tokens, &i)
                let dx = number(tokens, &i), dy = number(tokens, &i)
                path.addCurve(to: CGPoint(x: cp.x + dx, y: cp.y + dy),
                              controlPoint1: CGPoint(x: cp.x + x1, y: cp.y + y1),
                              controlPoint2: CGPoint(x: cp.x + x2, y: cp.y + y2))
            case "Z", "z":
                path.close()
            default:
                i += 1
            }
        }

        if fillRule == .evenOdd {
            path.usesEvenOddFillRule = true
        }
        return path
    }

    // MARK: - Tokenizer

    private static func tokenize(_ d: String) -> [String] {
        var tokens: [String] = []
        var current = ""

        for ch in d {
            if ch.isLetter {
                if !current.isEmpty { tokens.append(current); current = "" }
                tokens.append(String(ch))
            } else if ch == "," || ch == " " || ch == "\n" || ch == "\t" {
                if !current.isEmpty { tokens.append(current); current = "" }
            } else if ch == "-" && !current.isEmpty && current.last != "e" && current.last != "E" {
                tokens.append(current); current = String(ch)
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }

    private static func number(_ tokens: [String], _ i: inout Int) -> CGFloat {
        guard i < tokens.count, let v = Double(tokens[i]) else { return 0 }
        i += 1
        return CGFloat(v)
    }
}
