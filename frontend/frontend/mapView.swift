import SwiftUI
import MapKit
import CoreLocation

struct mapView: View {
    @State private var position: MapCameraPosition = .automatic
    @State private var locationManager = CLLocationManager()
    @Binding var searchResults: [MKMapItem]
    
    var body: some View {
        Map(position: $position, interactionModes: .all) {
            UserAnnotation()
        }
        .mapStyle(.standard(pointsOfInterest: .including([.foodMarket]), showsTraffic: true))
        .onAppear {
            requestLocationPermission()
            animateToUserLocation()
        }
    }
    
    private func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func animateToUserLocation() {
        // Get user's current location
        if let userLocation = locationManager.location {
            withAnimation(.easeInOut(duration: 1.0)) {
                position = .camera(MapCamera(
                    centerCoordinate: userLocation.coordinate,
                    distance: 5000,
                    heading: 0,
                    pitch: 0
                ))
            }
        }
    }
    
    private func search(for query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(
            center: locationManager.location!.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125)
        )
        
        Task{
            let search = MKLocalSearch(request: request)
            let response = try? await search.start()
            searchResults = response?.mapItems ?? []
        }
    }
}

#Preview {
    mapView()
}
