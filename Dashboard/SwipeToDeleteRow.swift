import SwiftUI

/// Swipe-left-to-delete for rows that are NOT inside a `List`.
/// The Dashboard renders transactions in a custom grouped day card,
/// so the native `.swipeActions` modifier is unavailable there.
///
/// The swipe only reveals the action — deletion requires a deliberate
/// tap on the Delete button.
struct SwipeToDeleteRow<Content: View>: View {

    /// Stable identity for this row, used to coordinate with sibling
    /// rows so only one can be open at a time.
    let id: ObjectIdentifier

    /// Shared across every row in the same list. When a row opens, it
    /// writes its own id here; every other row watches this value and
    /// closes itself the moment it no longer matches its own id.
    @Binding var openRowID: ObjectIdentifier?

    let onDelete: () -> Void

    @ViewBuilder var content: Content

    @State private var offsetX: CGFloat = 0
    @State private var isOpen = false

    private let actionWidth: CGFloat = 88
    private let activationThreshold: CGFloat = 44

    private let horizontalRatio: CGFloat = 2.5

    private let minimumHorizontalTravel: CGFloat = 24

    var body: some View {

        ZStack(alignment: .trailing) {

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
                                    openRowID = id

                                } else {

                                    offsetX = 0
                                    isOpen = false

                                    if openRowID == id {
                                        openRowID = nil
                                    }

                                }

                            }

                        }

                )

        }
        .clipped()
        .onChange(of: openRowID) { _, newValue in

            guard isOpen, newValue != id else {
                return
            }

            withAnimation(.easeOut(duration: 0.22)) {
                offsetX = 0
                isOpen = false
            }

        }

    }

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

        if openRowID == id {
            openRowID = nil
        }

    }

}
