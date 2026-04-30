import SwiftUI

struct StatusBarLabel: View {
    let title: String
    let showsIcon: Bool

    var body: some View {
        HStack(spacing: 5) {
            if showsIcon {
                Image(systemName: "calendar")
            }

            Text(title)
                .font(.ndMono(12, weight: .medium))
        }
    }
}

