import UIKit

enum DSSpacing {
    static let horizontalPadding: CGFloat = 16
    static let verticalSection: CGFloat = 24
    static let listItemSpacing: CGFloat = 12
    static let chipGap: CGFloat = 8
    static let innerCardPadding: CGFloat = 16
}

enum DSCornerRadius {
    static let card: CGFloat = 16
    static let inputField: CGFloat = 12

    static func capsule(height: CGFloat) -> CGFloat {
        height / 2
    }

    static func circle(size: CGFloat) -> CGFloat {
        size / 2
    }
}
