import Atoms
import SwiftUI

struct FilterPicker: View {
    @WatchState(FilterAtom())
    var filter

    var body: some View {
        Picker("Filter", selection: $filter) {
            ForEach(Filter.allCases, id: \.self) { filter in
                Text(filter.title)
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical)
    }
}

private extension Filter {
    var title: String {
        switch self {
        case .nowPlaying:
            return "Now"

        case .popular:
            return "Popular"

        case .topRated:
            return "Top"

        case .upcoming:
            return "Upcoming"
        }
    }
}
