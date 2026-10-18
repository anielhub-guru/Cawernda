import SwiftUI

enum BreakSkipKey: String {
    case escape
    case delete

    var displayName: String {
        switch self {
        case .escape: "Esc"
        case .delete: "Delete"
        }
    }
}

struct BreakSkipPressTracker {
    private(set) var armedKey: BreakSkipKey?
    private(set) var expiresAt: Date?

    mutating func register(
        _ key: BreakSkipKey,
        at date: Date,
        interval: TimeInterval = 2
    ) -> Bool {
        if armedKey == key, let expiresAt, date <= expiresAt {
            reset()
            return true
        }

        armedKey = key
        expiresAt = date.addingTimeInterval(interval)
        return false
    }

    mutating func reset() {
        armedKey = nil
        expiresAt = nil
    }
}

public struct LockOverlayView: View {
    let startedAt: Date
    let endsAt: Date
    let prompt: BreakPrompt
    let breaksToday: Int
    let skipsRemaining: Int?
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var skipPressTracker = BreakSkipPressTracker()
    @State private var skipResetTask: Task<Void, Never>? = nil

    // Deterministic static fractional positions for 10 dots
    private struct DotPosition: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
    }

    private let dotPositions = [
        DotPosition(x: 0.15, y: 0.20),
        DotPosition(x: 0.82, y: 0.15),
        DotPosition(x: 0.25, y: 0.78),
        DotPosition(x: 0.72, y: 0.85),
        DotPosition(x: 0.10, y: 0.52),
        DotPosition(x: 0.90, y: 0.48),
        DotPosition(x: 0.35, y: 0.28),
        DotPosition(x: 0.65, y: 0.22),
        DotPosition(x: 0.40, y: 0.70),
        DotPosition(x: 0.58, y: 0.75)
    ]

    public init(
        startedAt: Date,
        endsAt: Date,
        prompt: BreakPrompt,
        breaksToday: Int,
        skipsRemaining: Int?,
        onComplete: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.startedAt = startedAt
        self.endsAt = endsAt
        self.prompt = prompt
        self.breaksToday = breaksToday
        self.skipsRemaining = skipsRemaining
        self.onComplete = onComplete
        self.onSkip = onSkip
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                // Static dots scattered across the screen
                ForEach(dotPositions) { dot in
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 4, height: 4)
                        .position(x: dot.x * geometry.size.width, y: dot.y * geometry.size.height)
                }

                // Main Content View
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let duration = max(1, endsAt.timeIntervalSince(startedAt))
                    let elapsed = max(0, context.date.timeIntervalSince(startedAt))
                    let remaining = max(0, endsAt.timeIntervalSince(context.date))
                    let progress = min(1, remaining / duration)
                    let secondsInt = Int(ceil(remaining))

                    let minutes = secondsInt / 60
                    let seconds = secondsInt % 60
                    let timeString = String(format: "%d:%02d", minutes, seconds)

                    let currentTimeString = context.date.formatted(date: .omitted, time: .shortened)

                    VStack(spacing: 32) {
                        // Current wall-clock time
                        Text(currentTimeString)
                            .font(.system(size: 68, weight: .light, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()

                        // Circular countdown ring
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 4)
                                .frame(width: 120, height: 120)

                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1.0), value: progress)

                            Text(timeString)
                                .font(.system(size: 36, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }

                        BreakActivityAnimationView(prompt: prompt, phase: elapsed)
                            .frame(height: 88)
                            .accessibilityHidden(true)

                        // Messages group
                        VStack(spacing: 10) {
                            Text(prompt.instruction)
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 600)

                            Text(prompt.guidance)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.white.opacity(0.58))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 600)

                            Text(activitySummary)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.top, 6)
                        }
                    }
                    .onChange(of: secondsInt) { _, newValue in
                        if newValue <= 0 {
                            onComplete()
                        }
                    }
                }

                // Skip instruction and immediate first-press feedback
                VStack {
                    Spacer()
                    Text(skipInstruction)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(
                            skipPressTracker.armedKey == nil
                                ? .white.opacity(0.35)
                                : .white.opacity(0.8)
                        )
                        .padding(.bottom, 24)
                        .animation(.easeInOut(duration: 0.2), value: skipPressTracker.armedKey)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LockOverlaySkipKeyPressed"))) { notification in
            guard let rawValue = notification.object as? String,
                  let key = BreakSkipKey(rawValue: rawValue) else { return }
            handleSkipKeyPress(key)
        }
        .onDisappear { skipResetTask?.cancel() }
    }

    private var canSkip: Bool {
        skipsRemaining.map { $0 > 0 } ?? true
    }

    private var activitySummary: String {
        guard let skipsRemaining else {
            return "Rests today: \(breaksToday)"
        }
        return "Rests today: \(breaksToday)  •  Skips remaining: \(skipsRemaining)"
    }

    private var skipInstruction: String {
        guard canSkip else { return "Break skip limit reached" }
        guard let armedKey = skipPressTracker.armedKey else {
            return "Press Esc or Delete twice to skip"
        }
        return "Armed — press \(armedKey.displayName) once more to skip"
    }

    private func handleSkipKeyPress(_ key: BreakSkipKey) {
        guard canSkip else { return }

        skipResetTask?.cancel()
        let shouldSkip = withAnimation(.easeIn(duration: 0.2)) {
            skipPressTracker.register(key, at: Date())
        }
        if shouldSkip {
            onSkip()
            return
        }

        skipResetTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                skipPressTracker.reset()
            }
        }
    }
}

// MARK: - Break activity animations

struct BreakActivityAnimationView: View {
    let prompt: BreakPrompt
    let phase: Double

    @ViewBuilder
    var body: some View {
        switch prompt {
        case .standUp:
            Image(systemName: "figure.stand")
                .font(.system(size: 68, weight: .light))
                .foregroundStyle(.white)
                .offset(y: -abs(sin(phase * 1.4)) * 8)

        case .shortWalk:
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 68, weight: .light))
                .foregroundStyle(.white)
                .offset(x: sin(phase * 1.8) * 20)

        case .lookIntoDistance:
            LookAwayEyesView(phase: phase * 1.5)

        case .blinkSlowly:
            BlinkingEyesView(phase: phase)

        case .relaxShoulders:
            Image(systemName: "figure.arms.open")
                .font(.system(size: 68, weight: .light))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(sin(phase * 1.2) * 4))
                .scaleEffect(1 + abs(sin(phase * 1.2)) * 0.06)

        case .stretchHandsAndWrists:
            HStack(spacing: 28) {
                Image(systemName: "hand.raised.fill")
                    .rotationEffect(.degrees(-10 + sin(phase * 1.8) * 10))
                Image(systemName: "hand.raised.fill")
                    .scaleEffect(x: -1, y: 1)
                    .rotationEffect(.degrees(10 - sin(phase * 1.8) * 10))
            }
            .font(.system(size: 52, weight: .light))
            .foregroundStyle(.white)

        case .standAndReach:
            ZStack {
                Image(systemName: "figure.stand")
                    .font(.system(size: 68, weight: .light))
                HStack(spacing: 46) {
                    Image(systemName: "arrow.up")
                    Image(systemName: "arrow.up")
                }
                .font(.system(size: 18, weight: .semibold))
                .offset(y: -24 - abs(sin(phase * 1.4)) * 7)
            }
            .foregroundStyle(.white)
            .offset(y: -abs(sin(phase * 1.4)) * 4)

        case .breatheSlowly:
            BreatheAnimationView(phase: phase)
        }
    }
}

struct BlinkingEyesView: View {
    let phase: Double

    private var openness: CGFloat {
        1 - pow(max(0, sin(phase * 1.6)), 18) * 0.88
    }

    var body: some View {
        HStack(spacing: 20) {
            EyeView(pupilOffset: .zero)
            EyeView(pupilOffset: .zero)
        }
        .scaleEffect(x: 1, y: openness)
    }
}

struct BreatheAnimationView: View {
    let phase: Double

    private var expansion: CGFloat {
        0.78 + (sin(phase * 0.75) + 1) * 0.11
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .frame(width: 82, height: 82)
            Circle()
                .fill(Color.white.opacity(0.88))
                .frame(width: 66, height: 66)
                .scaleEffect(expansion)
        }
    }
}

// MARK: - LookAwayEyesView

struct LookAwayEyesView: View {
    let phase: Double

    var body: some View {
        HStack(spacing: 20) {
            EyeView(pupilOffset: pupilOffset)
            EyeView(pupilOffset: pupilOffset)
        }
    }

    private var pupilOffset: CGSize {
        let x = sin(phase) * 10
        let y = cos(phase * 0.72) * 5
        return CGSize(width: x, height: y)
    }
}

struct EyeView: View {
    let pupilOffset: CGSize

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.white.opacity(0.92))
                .frame(width: 76, height: 54)
                .overlay(
                    Ellipse()
                        .stroke(Color.white.opacity(0.22), lineWidth: 1.5)
                )

            // Pupil
            ZStack {
                Circle()
                    .fill(Color(white: 0.05).opacity(0.96))
                    .frame(width: 22, height: 22)

                // Glint
                Circle()
                    .fill(Color.white.opacity(0.78))
                    .frame(width: 5, height: 5)
                    .offset(x: -3, y: -3)
            }
            .offset(pupilOffset)
        }
    }
}
