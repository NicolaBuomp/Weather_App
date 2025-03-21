//
//  LocationService.swift
//  Weather_App
//
//  Created by Nicola Buompane on 15/03/25.
//

import Foundation
import CoreLocation
import Combine

enum LocationError: Error {
    case accessDenied
    case locationDisabled
    case unableToGetLocation
    
    var description: String {
        switch self {
        case .accessDenied:
            return "Accesso alla posizione negato. Abilitalo dalle impostazioni."
        case .locationDisabled:
            return "Servizi di localizzazione disattivati. Abilitali dalle impostazioni."
        case .unableToGetLocation:
            return "Impossibile ottenere la tua posizione attuale."
        }
    }
}

class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private var locationSubject = PassthroughSubject<CLLocation, LocationError>()
    
    var locationPublisher: AnyPublisher<CLLocation, LocationError> {
        return locationSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            locationSubject.send(completion: .failure(.accessDenied))
        @unknown default:
            locationSubject.send(completion: .failure(.unableToGetLocation))
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            locationSubject.send(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationSubject.send(completion: .failure(.unableToGetLocation))
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            locationSubject.send(completion: .failure(.accessDenied))
        case .notDetermined:
            break // Wait for user response
        @unknown default:
            locationSubject.send(completion: .failure(.unableToGetLocation))
        }
    }
}

