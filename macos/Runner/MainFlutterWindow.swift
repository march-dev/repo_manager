import Cocoa
import FlutterMacOS

// Below this width, the app's own layout (header cards, table columns,
// the nav rail) starts clipping/overlapping rather than reflowing —
// AppKit's own window resizing has no equivalent of Flutter's adaptive
// breakpoints, so the floor has to be enforced here instead.
private let kMinWindowWidth: CGFloat = 720
private let kMinWindowHeight: CGFloat = 600

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: kMinWindowWidth, height: kMinWindowHeight)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
