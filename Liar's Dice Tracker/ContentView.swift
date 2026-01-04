import SwiftUI

struct ContentView: View {
    private let maxQuantity = 300

    @State private var selectedQuantity: Int? = nil
    @State private var selectedPip: Int? = nil
    @State private var scrollQuantityToLeading: ((Int) -> Void)? = nil

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)

    @Environment(\.verticalSizeClass) private var vSize
    private var isLandscape: Bool { vSize == .compact }

    var body: some View {
        Group {
            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            lightImpact.prepare()
            mediumImpact.prepare()
        }
    }

    // MARK: - Portrait (3 rows)
    private var portraitLayout: some View {
        VStack(spacing: 16) {
            quantityRow(height: 72)

            HStack(spacing: 12) { pipButton(2, minHeight: 56, iconSize: 26)
                                 pipButton(3, minHeight: 56, iconSize: 26)
                                 pipButton(4, minHeight: 56, iconSize: 26) }

            HStack(spacing: 12) { pipButton(5, minHeight: 56, iconSize: 26)
                                 pipButton(6, minHeight: 56, iconSize: 26)
                                 resetButton(minHeight: 56, iconSize: 22) }

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Landscape (2 rows, second row must fit without scrolling)
    private var landscapeLayout: some View {
        VStack(spacing: 16) {
            quantityRow(height: 72)

            GeometryReader { geo in
                let spacing: CGFloat = 10
                // total spacing between 6 buttons = 5 gaps
                let totalGap = spacing * 5
                let available = geo.size.width - totalGap
                let rawSide = floor(available / 6)

                // Keep tap targets legal. If this ever can't fit, the device is *extremely* small.
                let side = max(44, rawSide)

                // Scale icon sizes with the button side
                let dieIcon = max(18, min(28, side * 0.48))
                let resetIcon = max(16, min(24, side * 0.40))

                HStack(spacing: spacing) {
                    pipButton(2, fixedSide: side, iconSize: dieIcon)
                    pipButton(3, fixedSide: side, iconSize: dieIcon)
                    pipButton(4, fixedSide: side, iconSize: dieIcon)
                    pipButton(5, fixedSide: side, iconSize: dieIcon)
                    pipButton(6, fixedSide: side, iconSize: dieIcon)
                    resetButton(fixedSide: side, iconSize: resetIcon)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            // Give the geometry reader a predictable height equal to the computed button side-ish.
            // 64 is a safe default; actual buttons are fixed by computed `side`.
            .frame(height: 72)

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Numerals
    private func quantityRow(height: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(1...maxQuantity, id: \.self) { n in
                        Button {
                            lightImpact.prepare()
                            lightImpact.impactOccurred()

                            selectedQuantity = n
                            withAnimation(.snappy) {
                                proxy.scrollTo(n, anchor: .leading)
                            }
                        } label: {
                            Text("\(n)")
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .frame(minWidth: 56, minHeight: 56)
                        }
                        .buttonStyle(BidButtonStyle(isSelected: selectedQuantity == n))
                        .id(n)
                    }
                }
                .padding(.vertical, 4)
            }
            .onAppear {
                scrollQuantityToLeading = { n in
                    withAnimation(.snappy) { proxy.scrollTo(n, anchor: .leading) }
                }
                proxy.scrollTo(1, anchor: .leading)
            }
        }
        .frame(height: height)
    }

    // MARK: - Pips / Reset (portrait uses flexible width; landscape uses fixed side)
    private func pipButton(_ pip: Int, minHeight: CGFloat, iconSize: CGFloat) -> some View {
        Button {
            lightImpact.prepare()
            lightImpact.impactOccurred()
            selectedPip = pip
        } label: {
            Image(systemName: "die.face.\(pip)")
                .font(.system(size: iconSize, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: minHeight)
        }
        .buttonStyle(BidButtonStyle(isSelected: selectedPip == pip))
        .accessibilityLabel("Pip \(pip)")
    }

    private func pipButton(_ pip: Int, fixedSide: CGFloat, iconSize: CGFloat) -> some View {
        Button {
            lightImpact.prepare()
            lightImpact.impactOccurred()
            selectedPip = pip
        } label: {
            Image(systemName: "die.face.\(pip)")
                .font(.system(size: iconSize, weight: .semibold))
                .frame(width: fixedSide, height: fixedSide)
        }
        .buttonStyle(BidButtonStyle(isSelected: selectedPip == pip))
        .accessibilityLabel("Pip \(pip)")
    }

    private func resetButton(minHeight: CGFloat, iconSize: CGFloat) -> some View {
        Button(action: reset) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: iconSize, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: minHeight)
        }
        .buttonStyle(BidButtonStyle(isSelected: false, isReset: true))
        .accessibilityLabel("Reset")
    }

    private func resetButton(fixedSide: CGFloat, iconSize: CGFloat) -> some View {
        Button(action: reset) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: iconSize, weight: .semibold))
                .frame(width: fixedSide, height: fixedSide)
        }
        .buttonStyle(BidButtonStyle(isSelected: false, isReset: true))
        .accessibilityLabel("Reset")
    }

    // MARK: - Actions
    private func reset() {
        mediumImpact.prepare()
        mediumImpact.impactOccurred()

        selectedQuantity = nil
        selectedPip = nil
        scrollQuantityToLeading?(1)
    }
}

struct BidButtonStyle: ButtonStyle {
    let isSelected: Bool
    var isReset: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? Color(.systemBackground) : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.primary : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isReset ? Color.secondary :
                        (isSelected ? Color.clear : Color.secondary.opacity(0.4)),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

