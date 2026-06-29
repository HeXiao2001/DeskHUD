import AppKit
import SwiftUI

/// Native Liquid Glass on macOS 26+; falls back to vibrant HUD material on older macOS.
private struct NativeGlassNSView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        // macOS 26: use NSGlassEffectView for native Liquid Glass
        if let glassClass = NSClassFromString("NSGlassEffectView") as? NSView.Type {
            let view = glassClass.init()
            view.wantsLayer = true
            return view
        }
        // Fallback: NSVisualEffectView with HUD material
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct NativeGlassView: View {
    var body: some View {
        NativeGlassNSView()
    }
}
