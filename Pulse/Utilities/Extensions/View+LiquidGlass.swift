import SwiftUI

// MARK: - Liquid Glass Convenience Extensions

extension View {
    /// Applies Liquid Glass effect with accessibility support
    /// Automatically falls back to .identity when reduce transparency is enabled
    @ViewBuilder
    func adaptiveGlassEffect(
        _ variant: Glass = .regular,
        reduceTransparency: Bool = false
    ) -> some View {
        if reduceTransparency {
            self.glassEffect(.identity)
        } else {
            self.glassEffect(variant)
        }
    }

    /// Applies a tinted glass effect with accessibility support
    @ViewBuilder
    func adaptiveGlassEffect(
        tint color: Color,
        reduceTransparency: Bool = false
    ) -> some View {
        if reduceTransparency {
            self.glassEffect(.identity)
        } else {
            self.glassEffect(.regular.tint(color))
        }
    }
}

// MARK: - Common Layout Helpers

extension View {
    /// Adds standard padding for card-like views
    func cardPadding() -> some View {
        self.padding()
    }

    /// Adds standard section spacing
    func sectionSpacing() -> some View {
        self.padding(.vertical, 8)
    }

    /// Wraps view in a glass effect container for grouped controls
    func glassContainer(reduceTransparency: Bool = false) -> some View {
        GlassEffectContainer {
            self
        }
    }
}

// MARK: - Conditional Modifiers

extension View {
    /// Applies a modifier conditionally
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Applies one of two modifiers based on condition
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        then trueTransform: (Self) -> TrueContent,
        else falseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueTransform(self)
        } else {
            falseTransform(self)
        }
    }
}

// MARK: - Debug Helpers

extension View {
    /// Prints debug information when view appears
    func debugPrint(_ message: String) -> some View {
        self.onAppear {
            print("🔍 \(message)")
        }
    }

    /// Shows a border in debug mode
    func debugBorder(_ color: Color = .red) -> some View {
        #if DEBUG
        self.border(color, width: 1)
        #else
        self
        #endif
    }
}
