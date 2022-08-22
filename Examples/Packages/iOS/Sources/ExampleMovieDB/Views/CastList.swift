import Atoms
import SwiftUI

struct CastList: View {
    let movieID: Int

    @ViewContext
    var context

    var casts: AsyncPhase<[Credits.Person], Error> {
        context.watch(CastsAtom(movieID: movieID).phase)
    }

    var body: some View {
        switch casts {
        case .suspending:
            ProgressRow()

        case .failure:
            CaveatRow(text: "Failed to get casts data.")

        case .success(let casts) where casts.isEmpty:
            CaveatRow(text: "No cast information is available.")

        case .success(let casts):
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(casts, id: \.id) { cast in
                        item(cast: cast)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func item(cast: Credits.Person) -> some View {
        VStack(spacing: 0) {
            ZStack {
                if let path = cast.profilePath {
                    NetworkImage(path: path, size: .cast)
                }
                else {
                    Image(systemName: "person.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color(.systemGray))
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground).ignoresSafeArea())

            Text(cast.name)
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(2)
                .padding(4)
                .frame(height: 40)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(width: 80)
        .background(Color(.systemBackground).ignoresSafeArea())
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray3), lineWidth: 0.5)
        )
    }
}
