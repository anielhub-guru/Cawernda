import AppKit

enum AlarmClockMenuIcon {
    static func make() -> NSImage {
        let image = NSImage(size: NSSize(width: 19, height: 18), flipped: false) { _ in
            NSColor.labelColor.setStroke()

            let body = NSBezierPath(ovalIn: NSRect(x: 3.25, y: 2.35, width: 12.5, height: 12.5))
            body.lineWidth = 1.75
            body.stroke()

            let bells = NSBezierPath()
            bells.lineWidth = 1.75
            bells.lineCapStyle = .round
            bells.lineJoinStyle = .round
            bells.move(to: NSPoint(x: 5.1, y: 13.8))
            bells.curve(
                to: NSPoint(x: 1.6, y: 13.0),
                controlPoint1: NSPoint(x: 3.7, y: 15.7),
                controlPoint2: NSPoint(x: 1.8, y: 15.2)
            )
            bells.curve(
                to: NSPoint(x: 4.2, y: 11.7),
                controlPoint1: NSPoint(x: 1.5, y: 11.8),
                controlPoint2: NSPoint(x: 2.8, y: 11.1)
            )
            bells.move(to: NSPoint(x: 13.9, y: 13.8))
            bells.curve(
                to: NSPoint(x: 17.4, y: 13.0),
                controlPoint1: NSPoint(x: 15.3, y: 15.7),
                controlPoint2: NSPoint(x: 17.2, y: 15.2)
            )
            bells.curve(
                to: NSPoint(x: 14.8, y: 11.7),
                controlPoint1: NSPoint(x: 17.5, y: 11.8),
                controlPoint2: NSPoint(x: 16.2, y: 11.1)
            )
            bells.stroke()

            let topButton = NSBezierPath(roundedRect: NSRect(x: 7.55, y: 15.35, width: 3.9, height: 1.35), xRadius: 0.65, yRadius: 0.65)
            topButton.lineWidth = 1.55
            topButton.stroke()

            let feet = NSBezierPath()
            feet.lineWidth = 1.75
            feet.lineCapStyle = .round
            feet.move(to: NSPoint(x: 5.25, y: 3.1))
            feet.line(to: NSPoint(x: 3.65, y: 0.95))
            feet.move(to: NSPoint(x: 13.75, y: 3.1))
            feet.line(to: NSPoint(x: 15.35, y: 0.95))
            feet.stroke()

            let hands = NSBezierPath()
            hands.lineWidth = 1.75
            hands.lineCapStyle = .round
            hands.lineJoinStyle = .round
            hands.move(to: NSPoint(x: 6.65, y: 10.3))
            hands.line(to: NSPoint(x: 9.5, y: 8.15))
            hands.line(to: NSPoint(x: 12.55, y: 10.85))
            hands.stroke()

            let center = NSBezierPath(ovalIn: NSRect(x: 8.65, y: 7.3, width: 1.7, height: 1.7))
            center.lineWidth = 1.35
            center.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Cawernda alarms"
        return image
    }
}
