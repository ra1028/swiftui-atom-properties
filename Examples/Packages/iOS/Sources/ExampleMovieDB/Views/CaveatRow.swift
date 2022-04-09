import SwiftUI

struct CaveatRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body.bold())
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical)
    }
}
