import CoreText
import Foundation

/// Registers every bundled font file with Core Text at launch, so the custom
/// `OcheFont` faces resolve by their PostScript names without needing
/// `UIAppFonts` entries in a (generated) Info.plist. Safe to call more than
/// once — re-registering an already-registered font is a no-op error we ignore.
enum FontLoader {
    static func registerBundledFonts() {
        for ext in ["ttf", "otf"] {
            let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            for url in urls {
                _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}
