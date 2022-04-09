import Atoms
import SwiftUI

struct NetworkImage: View {
    let path: String
    let size: ImageSize

    @ViewContext
    var context

    var image: Task<UIImage, Error> {
        context.watch(ImageAtom(path: path, size: size))
    }

    var body: some View {
        Suspense(image) { uiImage in
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        } suspending: {
            ProgressView()
        }
    }
}
