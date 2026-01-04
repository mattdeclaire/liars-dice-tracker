import SwiftUI

struct ContentView: View {
    // “Infinite” numerals
    @State private var maxQuantity: Int = 200
    private let extendThreshold = 30
    private let extendBy = 200

    @State private var selectedQuantity: Int? = nil
    @State private var selectedPip: Int? = nil
    @State private var scrollQuantityToLeading: ((Int) -> Void)? = nil

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)

    private let gutter: CGFloat = 16

    @Environment(\.verticalSizeClass) private var vSize
    private var isLandscape: Bool { vSize == .compact }

    var body: some View {
        GeometryReader { geo in
            let rowCount = isLandscape ? 2 : 4
            let rowGapCount = rowCount - 1

            // Height available for actual rows after outer gutters + inter-row gutters
            let availableHeight = geo.size.height - (gutter * 2) - (gutter * CGFloat(rowGapCount))

            VStack(spacing: gutter) {
                if isLandscape {
                    numeralsRow(rowHeight: availableHeight * 0.3)

                    equalWidthRow(
                        items: [.pip(2), .pip(3), .pip(4), .pip(5), .pip(6), .reset],
                        rowHeight: availableHeight * 0.7,
                        containerWidth: geo.size.width
                    )
                } else {
                    numeralsRow(rowHeight: availableHeight * 0.15)
                    
                    let pipHeight = availableHeight * 0.25
                    // Rows 2–4: two items per row, equal width
                    equalWidthRow(
                        items: [.pip(2), .pip(3)],
                        rowHeight: pipHeight,
                        containerWidth: geo.size.width
                    )
                    equalWidthRow(
                        items: [.pip(4), .pip(5)],
                        rowHeight: pipHeight,
                        containerWidth: geo.size.width
                    )
                    equalWidthRow(
                        items: [.pip(6), .reset],
                        rowHeight: pipHeight,
                        containerWidth: geo.size.width
                    )
                }
            }
            .padding(.all, gutter)
        }
        .onAppear {
            lightImpact.prepare()
            mediumImpact.prepare()
        }
    }

    // MARK: - Numerals row (denser buttons)

    private func numeralsRow(rowHeight: CGFloat) -> some View {
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: gutter) {
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
                                .font(.system(size: 54, weight: .semibold, design: .rounded))
                                .frame(width: rowHeight, height: rowHeight)
                        }
                        .buttonStyle(BidButtonStyle(isSelected: selectedQuantity == n))
                        .id(n)
                        .onAppear {
                            if n >= maxQuantity - extendThreshold {
                                maxQuantity += extendBy
                            }
                        }
                    }
                }
                .padding(.horizontal, gutter)  // 16pt gutter inside the scroll row too
            }
            .onAppear {
                scrollQuantityToLeading = { n in
                    withAnimation(.snappy) {
                        proxy.scrollTo(n, anchor: .leading)
                    }
                }
                proxy.scrollTo(1, anchor: .leading)
            }
        }
        .frame(height: rowHeight)
    }

    // MARK: - Equal-width pip/reset rows

    private enum RowItem {
        case pip(Int)
        case reset
    }

    private func equalWidthRow(items: [RowItem], rowHeight: CGFloat, containerWidth: CGFloat) -> some View {
        let count = items.count
        let gapCount = max(0, count - 1)

        // Total horizontal space for buttons after outer gutters and inner gutters between buttons
        let availableWidth = containerWidth - (gutter * 2) - (gutter * CGFloat(gapCount))
        let buttonWidth = availableWidth / CGFloat(count)

        return HStack(spacing: gutter) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                switch item {
                case .pip(let pip):
                    pipCell(pip: pip, width: buttonWidth, height: rowHeight)
                case .reset:
                    resetCell(width: buttonWidth, height: rowHeight)
                }
            }
        }
        .frame(height: rowHeight)
    }

    private func pipCell(pip: Int, width: CGFloat, height: CGFloat) -> some View {
        Button {
            lightImpact.prepare()
            lightImpact.impactOccurred()
            selectedPip = pip
        } label: {
            ZStack {
                if selectedPip == pip {
                    RoundedRectangle(cornerRadius: width * 0.18, style: .continuous)
                        .fill(Color(red: 0.6, green: 0.8, blue: 0.5))
                }
                Image(systemName: "die.face.\(pip)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color.primary)
            }
            .frame(width: width, height: height)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Pip \(pip)")
    }

    private func resetCell(width: CGFloat, height: CGFloat) -> some View {
        Button {
            mediumImpact.prepare()
            mediumImpact.impactOccurred()
            selectedQuantity = nil
            selectedPip = nil
            scrollQuantityToLeading?(1)
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 80, weight: .semibold))
                .frame(width: width, height: height)
                .contentShape(Rectangle())
        }
        .buttonStyle(BidButtonStyle(isSelected: false, isReset: true))
        .accessibilityLabel("Reset")
    }

}

struct BidButtonStyle: ButtonStyle {
    let isSelected: Bool
    var isReset: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(isSelected ? Color(red: 0.6, green: 0.8, blue: 0.5) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color(.black), lineWidth: 14)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.05), value: configuration.isPressed)
    }
}

