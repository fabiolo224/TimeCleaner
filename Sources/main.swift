import Cocoa
import SwiftUI

NSApplication.shared.setActivationPolicy(.accessory)
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
