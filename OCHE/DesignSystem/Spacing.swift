import CoreGraphics

/// Named padding/gap scale — replaces the ad-hoc 8/12/14/16/20/24/32 literals
/// scattered across views with one shared vocabulary.
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}
