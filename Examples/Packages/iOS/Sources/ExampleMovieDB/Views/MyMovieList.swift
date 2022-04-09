import Atoms
import SwiftUI

struct MyMovieList: View {
    @Watch(MyListAtom())
    var myList

    var onSelect: (Movie) -> Void

    var body: some View {
        if myList.isEmpty {
            emptyContent
        }
        else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(myList, id: \.id) { movie in
                        item(movie: movie)
                    }
                }
                .padding(.vertical)
            }
        }
    }

    var emptyContent: some View {
        HStack {
            Text("Tap")
            MyListButtonLabel(isOn: false)
            Text("to add movies here.")
        }
        .font(.body.bold())
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
    }

    func item(movie: Movie) -> some View {
        Button {
            onSelect(movie)
        } label: {
            ZStack {
                if let path = movie.posterPath {
                    NetworkImage(path: path, size: .medium)
                }
            }
            .frame(width: 80, height: 120)
            .background(Color(.systemGroupedBackground))
            .cornerRadius(8)
        }
    }
}
