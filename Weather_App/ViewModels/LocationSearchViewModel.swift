import Foundation
import Combine
import CoreLocation


struct LocationSuggestion: Identifiable, Codable {
    let id: UUID
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
    
    // Fornisci un inizializzatore con ID generato automaticamente
    init(id: UUID = UUID(), name: String, country: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // Helper per verificare se questa suggestion corrisponde a una FavoriteCity
    func matches(_ city: FavoriteCity) -> Bool {
        return name == city.name &&
               country == city.country &&
               latitude == city.latitude &&
               longitude == city.longitude
    }
}

class LocationSearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var suggestions: [LocationSuggestion] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var recentSearches: [LocationSuggestion] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let locationService = LocationService()
    private let recentSearchesKey = "recentSearches"
    private let maxRecentSearches = 5
    
    init() {
        // Carica ricerche recenti
        loadRecentSearches()
        
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
    
    // Aggiunge una suggestion alla cronologia di ricerca
    func addToRecentSearches(_ suggestion: LocationSuggestion) {
        // Rimuove se già presente
        recentSearches.removeAll { $0.name == suggestion.name && $0.country == suggestion.country }
        
        // Aggiunge all'inizio
        recentSearches.insert(suggestion, at: 0)
        
        // Limita il numero
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        // Salva
        saveRecentSearches()
    }
    
    // Carica le ricerche recenti
    private func loadRecentSearches() {
        guard let data = UserDefaults.standard.data(forKey: recentSearchesKey) else {
            return
        }
        
        do {
            let searches = try JSONDecoder().decode([LocationSuggestion].self, from: data)
            recentSearches = searches
        } catch {
            errorMessage = "Errore nel caricamento delle ricerche recenti"
        }
    }
    
    // Salva le ricerche recenti
    private func saveRecentSearches() {
        do {
            let data = try JSONEncoder().encode(recentSearches)
            UserDefaults.standard.set(data, forKey: recentSearchesKey)
        } catch {
            errorMessage = "Errore nel salvataggio delle ricerche recenti"
        }
    }
    
    // Cancella la cronologia delle ricerche
    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
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
