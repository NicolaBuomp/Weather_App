import Foundation
import Combine
import CoreLocation

class FavoriteCitiesViewModel: ObservableObject {
    @Published var favoriteCities: [FavoriteCity] = []
    @Published var errorMessage: String?
    @Published var isCurrentCityFavorited: Bool = false
    
    private let repository: FavoriteCitiesRepositoryProtocol
    private let weatherViewModel: WeatherViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: FavoriteCitiesRepositoryProtocol = FavoriteCitiesRepository(), weatherViewModel: WeatherViewModel) {
        self.repository = repository
        self.weatherViewModel = weatherViewModel
        
        repository.favoriteCitiesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cities in
                self?.favoriteCities = cities
                self?.checkCurrentCityFavoriteStatus()
            }
            .store(in: &cancellables)
        
        weatherViewModel.$weatherData
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkCurrentCityFavoriteStatus()
            }
            .store(in: &cancellables)
            
        checkCurrentCityFavoriteStatus()
    }
    
    func checkCurrentCityFavoriteStatus() {
        if let currentCity = createFavoriteCityFromCurrentWeather() {
            isCurrentCityFavorited = favoriteCities.contains(where: { $0 == currentCity })
        } else {
            isCurrentCityFavorited = false
        }
    }
    
    func addFavoriteCity(city: FavoriteCity) {
        if !repository.saveFavoriteCity(city) {
            errorMessage = "Impossibile salvare la città nei preferiti."
        }
        checkCurrentCityFavoriteStatus()
    }
    
    func addFavoriteCity(from suggestion: LocationSuggestion) {
        let city = FavoriteCity(from: suggestion)
        addFavoriteCity(city: city)
    }
    
    func removeFavoriteCity(city: FavoriteCity) {
        if !repository.removeFavoriteCity(city) {
            errorMessage = "Impossibile rimuovere la città dai preferiti."
        }
        checkCurrentCityFavoriteStatus()
    }
    
    func isCityFavorite(name: String, country: String) -> Bool {
        return repository.isCityFavorite(name: name, country: country)
    }
    
    func isSuggestionFavorite(_ suggestion: LocationSuggestion) -> Bool {
        return favoriteCities.contains(where: { $0.matches(suggestion) })
    }
    
    func selectCity(city: FavoriteCity) {
        weatherViewModel.searchLocation = city.coordinates
        weatherViewModel.search()
    }
    
    func createFavoriteCityFromCurrentWeather() -> FavoriteCity? {
        guard let weatherData = weatherViewModel.weatherData else {
            return nil
        }
        return FavoriteCity(
            name: weatherData.location.name,
            country: weatherData.location.country,
            latitude: weatherData.location.lat,
            longitude: weatherData.location.lon
        )
    }
    
    func isCurrentCityFavorite() -> Bool {
        guard let currentCity = createFavoriteCityFromCurrentWeather() else {
            return false
        }
        let isFavorite = favoriteCities.contains(where: { $0 == currentCity })
        if isCurrentCityFavorited != isFavorite {
            isCurrentCityFavorited = isFavorite
        }
        return isFavorite
    }
    
    func toggleCurrentCityFavorite() -> Bool {
        guard let currentCity = createFavoriteCityFromCurrentWeather() else {
            return false
        }
        
        if isCurrentCityFavorite() {
            if let existingCity = favoriteCities.first(where: { $0 == currentCity }) {
                removeFavoriteCity(city: existingCity)
                return false
            }
            return false
        } else {
            addFavoriteCity(city: currentCity)
            return true
        }
    }
    
    // Nuovo metodo per cancellare tutti i preferiti
    func clearFavorites() {
        if !repository.clearFavorites() {
            errorMessage = "Errore durante la rimozione di tutti i preferiti."
        }
        checkCurrentCityFavoriteStatus()
    }
}
