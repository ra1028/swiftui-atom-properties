import SwiftUI

struct MyListButtonLabel: View {
    let isOn: Bool

    var body: some View {
        VStack {
            Image(systemName: isOn ? "heart.fill" : "heart")
                .font(.title2)
                .foregroundStyle(.pink)

            Text("My List")
                .font(.system(.caption2))
                .foregroundColor(.pink)
        }
    }
}
