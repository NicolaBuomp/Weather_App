//
//  LocationSearchViewModel.swift
//  Weather_App
//
//  Created by Nicola Buompane on 15/03/25.
//

import Foundation
import Combine
import CoreLocation

struct LocationSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    
    var displayName: String {
        return "\(name), \(country)"
    }
    
    var coordinates: String {
        return "\(latitude),\(longitude)"
    }
}

class LocationSearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var suggestions: [LocationSuggestion] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let locationService = LocationService()
    
    init() {
        // Debounce search to avoid too many API calls
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .filter { !$0.isEmpty && $0.count >= 2 }
            .sink { [weak self] query in
                self?.fetchSuggestions(for: query)
            }
            .store(in: &cancellables)
    }
    
    func fetchSuggestions(for query: String) {
        guard !query.isEmpty else {
            self.suggestions = []
            return
        }
        
        isSearching = true
        
        // Create URL components for the API
        var components = URLComponents(string: "\(Constants.weatherApiBaseUrl)/search.json")
        components?.queryItems = [
            URLQueryItem(name: "key", value: Constants.weatherApiKey),
            URLQueryItem(name: "q", value: query)
        ]
        
        guard let url = components?.url else {
            isSearching = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [LocationSearchResponse].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isSearching = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Errore durante la ricerca: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] locations in
                self?.suggestions = locations.map { location in
                    LocationSuggestion(
                        name: location.name,
                        country: location.country,
                        latitude: location.lat,
                        longitude: location.lon
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    func getCurrentLocation() {
        locationService.requestLocation()
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.description
                }
            } receiveValue: { [weak self] location in
                self?.searchText = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
            }
            .store(in: &cancellables)
    }
}

// Response model for location search API
struct LocationSearchResponse: Codable {
    let id: Int
    let name: String
    let region: String
    let country: String
    let lat: Double
    let lon: Double
    let url: String
}

