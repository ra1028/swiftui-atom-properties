import Atoms
import MapKit
import SwiftUI

struct MapView: View {
    @Watch(CoordinateAtom())
    var coordinate

    var body: some View {
        MapViewRepresentable(base: self)
    }
}

private struct MapViewRepresentable: UIViewRepresentable {
    let base: MapView

    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        guard let coordinate = base.coordinate else {
            return
        }

        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate

        view.addAnnotation(annotation)
        view.setRegion(region, animated: true)
    }
}
