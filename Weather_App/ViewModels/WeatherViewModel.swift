import Foundation
import Combine

// Enum per tenere traccia dello stato di caricamento
enum LoadingState {
    case idle
    case loading
    case loaded
    case error(String)
}

class WeatherViewModel: ObservableObject {
    // Published properties che aggiornano automaticamente la UI quando cambiano
    @Published var weatherData: WeatherResponse?
    @Published var loadingState: LoadingState = .idle
    @Published var searchLocation: String = Constants.defaultLocation
    
    private let weatherService = WeatherService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Carichiamo i dati del meteo per la località predefinita all'avvio
        fetchWeather(for: searchLocation)
    }
    
    // Metodo per recuperare i dati meteo
    func fetchWeather(for location: String) {
        loadingState = .loading
        
        weatherService.fetchWeather(for: location)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.loadingState = .error(error.description)
                    }
                },
                receiveValue: { [weak self] response in
                    self?.weatherData = response
                    self?.loadingState = .loaded
                }
            )
            .store(in: &cancellables)
    }
    
    // Metodo per avviare una nuova ricerca
    func search() {
        fetchWeather(for: searchLocation)
    }
    
    
    // Recupera la temperatura corrente formattata
    var currentTemperature: String {
        guard let temp = weatherData?.current.tempC else { return "N/A" }
        return String(format: "%.1f°C", temp)
    }
    
    // Recupera la condizione meteo corrente
    var currentCondition: String {
        return weatherData?.current.condition.text ?? "N/A"
    }
    
    // Recupera l'URL dell'icona della condizione meteo corrente
    var currentConditionIconURL: URL? {
        return weatherData?.current.condition.iconUrl
    }
    
    // Controlla se è giorno o notte
    var isDaytime: Bool {
        return weatherData?.current.isDaytime ?? true
    }
    
    // Recupera la temperatura percepita
    var feelsLikeTemperature: String {
        guard let temp = weatherData?.current.feelslikeC else { return "N/A" }
        return String(format: "%.1f°C", temp)
    }
    
    // Recupera l'umidità corrente
    var humidity: String {
        guard let humidity = weatherData?.current.humidity else { return "N/A" }
        return "\(humidity)%"
    }
    
    // Recupera la velocità del vento
    var windSpeed: String {
        guard let speed = weatherData?.current.windKph else { return "N/A" }
        return String(format: "%.1f km/h", speed)
    }
    
    // Recupera la direzione del vento
    var windDirection: String {
        return weatherData?.current.windDir ?? "N/A"
    }
    
    // Recupera la probabilità di pioggia per oggi
    var chanceOfRain: String {
        guard let chance = weatherData?.forecast.forecastday.first?.day.dailyChanceOfRain else { return "N/A" }
        return "\(chance)%"
    }
    
    // Recupera l'indice UV
    var uvIndex: String {
        guard let uv = weatherData?.current.uv else { return "N/A" }
        return String(format: "%.1f", uv)
    }
    
    // Recupera la previsione per i prossimi giorni
    var forecastDays: [ForecastDay] {
        return weatherData?.forecast.forecastday ?? []
    }
    
    // Recupera le previsioni orarie per oggi
    var hourlyForecast: [Hour] {
        return weatherData?.forecast.forecastday.first?.hour ?? []
    }
}
