import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    @Published var locationName: String = "UnknownLocation"

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            // Perform reverse geocoding to get the location name
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                guard let self = self else { return }
                if let error = error {
                    print("Failed to get location name: \(error.localizedDescription)")
                    return
                }
                if let placemark = placemarks?.first {
                    self.locationName = self.getLocationName(from: placemark)
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let clError = error as? CLError else {
            print("Unknown error: \(error.localizedDescription)")
            return
        }
        switch clError.code {
        case .denied:
            print("Location services are denied by the user.")
            // Prompt the user to enable location services
        case .locationUnknown:
            print("Location is currently unknown.")
        default:
            print("Location manager failed with error: \(error.localizedDescription)")
        }
    }

    private func getLocationName(from placemark: CLPlacemark) -> String {
        // Construct a location name from placemark data
        if let name = placemark.name, let city = placemark.locality {
            return "\(name), \(city)"
        } else if let city = placemark.locality {
            return city
        } else if let country = placemark.country {
            return country
        } else {
            return "UnknownLocation"
        }
    }
}
