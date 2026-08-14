import SwiftUI

/// Swipe-left-to-delete for rows that are NOT inside a `List`.
/// The Dashboard renders transactions in a custom grouped day card,
/// so the native `.swipeActions` modifier is unavailable there.
///
/// The swipe only reveals the action — deletion requires a deliberate
/// tap on the Delete button.
struct SwipeToDeleteRow<Content: View>: View {

    let onDelete: () -> Void

    @ViewBuilder var content: Content

    @State private var offsetX: CGFloat = 0
    @State private var isOpen = false

    private let actionWidth: CGFloat = 88
    private let activationThreshold: CGFloat = 44

    /// How much more horizontal than vertical a drag must be before it
    /// counts as a swipe. Higher = harder to trigger accidentally while
    /// scrolling. 2.5 means the finger must travel 2.5x further sideways
    /// than up/down.
    private let horizontalRatio: CGFloat = 2.5

    /// Minimum sideways travel before the row responds at all.
    private let minimumHorizontalTravel: CGFloat = 24

    var body: some View {

        ZStack(alignment: .trailing) {

            // MARK: Destructive action (revealed behind the row)

            Button(role: .destructive) {

                close()
                onDelete()

            } label: {

                VStack(spacing: 4) {

                    Image(systemName: "trash.fill")
                        .font(.system(size: 17, weight: .semibold))

                    Text("Delete")
                        .font(.caption2)
                        .fontWeight(.semibold)

                }
                .foregroundStyle(.white)
                .frame(width: actionWidth)
                .frame(maxHeight: .infinity)
                .background(AppColors.danger)
                .contentShape(Rectangle())

            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete transaction")
            .opacity(offsetX < -8 ? 1 : 0)
            .allowsHitTesting(isOpen)

            // MARK: Row content

            content
                .background(AppColors.card)
                .offset(x: offsetX)
                .simultaneousGesture(

                    DragGesture(minimumDistance: 24)

                        .onChanged { value in

                            guard isHorizontal(value.translation) else {
                                return
                            }

                            let base = isOpen ? -actionWidth : 0
                            let proposed = base + value.translation.width

                            offsetX = min(0, max(-actionWidth, proposed))

                        }

                        .onEnded { value in

                            guard isHorizontal(value.translation) else {

                                close()
                                return

                            }

                            withAnimation(.easeOut(duration: 0.22)) {

                                if offsetX < -activationThreshold {

                                    offsetX = -actionWidth
                                    isOpen = true

                                } else {

                                    offsetX = 0
                                    isOpen = false

                                }

                            }

                        }

                )

        }
        .clipped()

    }

    // MARK: - Gesture Classification

    /// A drag only counts as a swipe when it is clearly sideways.
    /// This keeps vertical scrolling and diagonal drags from opening
    /// the delete action by accident.
    private func isHorizontal(_ translation: CGSize) -> Bool {

        let horizontal = abs(translation.width)
        let vertical = abs(translation.height)

        guard horizontal >= minimumHorizontalTravel else {
            return false
        }

        return horizontal > vertical * horizontalRatio

    }

    private func close() {

        withAnimation(.easeOut(duration: 0.22)) {
            offsetX = 0
            isOpen = false
        }

    }

}
