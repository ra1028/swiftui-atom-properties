import Atoms
import SwiftUI

struct MapScreen: View {
    @Watch(AuthorizationStatusAtom())
    var authorizationStatus

    @ViewContext
    var context

    var body: some View {
        Group {
            switch authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                mapContent

            case .notDetermined, .restricted, .denied:
                authorizationContent

            @unknown default:
                authorizationContent
            }
        }
        .navigationTitle("Map")
    }

    var mapContent: some View {
        MapView()
            .ignoresSafeArea(edges: [.bottom, .leading, .trailing])
            .overlay(alignment: .topTrailing) {
                Button {
                    context.reset(CoordinateAtom())
                } label: {
                    Image(systemName: "location")
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .padding()
                .shadow(radius: 2)
            }
    }

    var authorizationContent: some View {
        ZStack {
            Button("Open Settings") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            .tint(.blue)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
        }
    }
}

struct ExampleScreen_Preview: PreviewProvider {
    static var previews: some View {
        AtomRoot {
            MapScreen()
        }
    }
}
