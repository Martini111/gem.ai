import SwiftUI

/// Math utilities for an Archimedean spiral r(θ) = a + bθ.
struct SpiralParams: Sendable {
    var distanceToCenter: CGFloat   // a
    var distanceBetweenCircles: CGFloat  // Δr per full 2π turn

    init(distanceToCenter: CGFloat, distanceBetweenCircles: CGFloat) {
        self.distanceToCenter = distanceToCenter
        self.distanceBetweenCircles = distanceBetweenCircles
    }
}

enum SpiralMath {
    // MARK: - Core geometry

    /// b such that each full turn increases radius by distanceBetweenCircles.
    @inlinable
    static func b(_ p: SpiralParams) -> CGFloat {
        let spacing = max(p.distanceBetweenCircles, .ulpOfOne)
        return spacing / (2 * .pi)
    }

    /// r(θ) = a + bθ
    @inlinable
    static func radius(a: CGFloat, b: CGFloat, theta: CGFloat) -> CGFloat {
        a + b * theta
    }

    /// Arc length from 0 to θ for r = a + bθ: s(θ) = (b/2)θ² + aθ
    @inlinable
    static func arcLength(a: CGFloat, b: CGFloat, theta: CGFloat) -> CGFloat {
        (b * 0.5) * theta * theta + a * theta
    }

    /// Invert arc length to θ for s = (b/2)θ² + aθ.
    @inlinable
    static func theta(fromArcLength s: CGFloat, a: CGFloat, b: CGFloat) -> CGFloat {
        let bSafe = max(b, 0.0001)
        let disc = max(0, a * a + 2 * bSafe * max(0, s))
        return (-a + sqrt(disc)) / bSafe
    }

    /// Cartesian point for given θ and center.
    @inlinable
    static func point(center: CGPoint, a: CGFloat, b: CGFloat, theta: CGFloat) -> CGPoint {
        let r = radius(a: a, b: b, theta: theta)
        return CGPoint(x: center.x + r * cos(theta), y: center.y + r * sin(theta))
    }

    /// Visible θ end given rect and optional overscan.
    @inlinable
    static func thetaEndVisible(in rect: CGRect, params p: SpiralParams, overscan: CGFloat = 0) -> CGFloat {
        let a = max(0, p.distanceToCenter)
        let bVal = b(p)
        let halfDiagonal = 0.5 * hypot(rect.width, rect.height)
        let rVisibleMax = halfDiagonal + overscan
        guard rVisibleMax > a else { return 0 }
        return (rVisibleMax - a) / bVal
    }

    // MARK: - Modulo and array helpers

    @inlinable
    static func posMod(_ x: Int, _ m: Int) -> Int {
        guard m > 0 else { return 0 }
        let r = x % m
        return r < 0 ? r + m : r
    }

    @inlinable
    static func posMod(_ x: CGFloat, _ m: CGFloat) -> CGFloat {
        guard m > 0 else { return 0 }
        var r = x.truncatingRemainder(dividingBy: m)
        if r < 0 { r += m }
        return r
    }

    // MARK: - Carousel specific helpers

    /// Center index based on offset and per-item spacing.
    @inlinable
    static func centerIndex(numberOfItems n: Int, distanceBetweenItems: CGFloat, spiralOffset: CGFloat) -> Int {
        guard n > 0, distanceBetweenItems > 0 else { return 0 }
        let total = CGFloat(n) * distanceBetweenItems
        let norm = posMod(total - spiralOffset, total)
        let start = Int(ceil(norm / distanceBetweenItems))
        return posMod(start, n)
    }

    /// Tail (last) index in the circular ordering — the item immediately before the center.
    /// This is useful when you need the index of the item at the tail end of the logical sequence.
    @inlinable
    static func tailIndex(numberOfItems n: Int, distanceBetweenItems: CGFloat, spiralOffset: CGFloat) -> Int {
        guard n > 0, distanceBetweenItems > 0 else { return 0 }
        let center = centerIndex(numberOfItems: n, distanceBetweenItems: distanceBetweenItems, spiralOffset: spiralOffset)
        return posMod(center - 1, n)
    }

    /// Position of an item by index with infinite looping along arc length.
    @inlinable
    static func position(center: CGPoint,
                         index: Int,
                         numberOfItems n: Int,
                         distanceBetweenItems: CGFloat,
                         spiralOffset: CGFloat,
                         params p: SpiralParams) -> CGPoint {
        let a = p.distanceToCenter
        let bVal = b(p)
        let totalS = CGFloat(n) * distanceBetweenItems
        let adjusted = posMod(CGFloat(index) * distanceBetweenItems + spiralOffset, totalS)
        let theta = theta(fromArcLength: adjusted, a: a, b: bVal)
        return point(center: center, a: a, b: bVal, theta: theta)
    }
}
