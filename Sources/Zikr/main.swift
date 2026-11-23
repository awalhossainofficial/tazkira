import AppKit

let app = NSApplication.shared
// Menu-bar only: no Dock icon and no main window.
app.setActivationPolicy(.accessory)
let controller = AppController()
app.delegate = controller
app.run()
