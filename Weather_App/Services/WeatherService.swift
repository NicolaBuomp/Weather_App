import Foundation
import Combine

enum WeatherError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    
    var description: String {
        switch self {
        case .invalidURL:
            return "URL non valido."
        case .invalidResponse:
            return "Risposta dal server non valida."
        case .networkError(let error):
            return "Errore di rete: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Errore nella decodifica dei dati: \(error.localizedDescription)"
        }
    }
}

class WeatherService {
    func fetchWeather(for location: String) -> AnyPublisher<WeatherResponse, WeatherError> {
        let components = createUrlComponents(for: location)
        
        guard let url = components.url else {
            return Fail(error: WeatherError.invalidURL).eraseToAnyPublisher()
        }
        
        print("Requesting URL: \(url.absoluteString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .mapError { WeatherError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<WeatherResponse, WeatherError> in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    return Fail(error: WeatherError.invalidResponse).eraseToAnyPublisher()
                }
                
                // Log della risposta per debug
                print("Response status code: \(httpResponse.statusCode)")
                
                let decoder = JSONDecoder()
                
                return Just(data)
                    .decode(type: WeatherResponse.self, decoder: decoder)
                    .mapError { error -> WeatherError in
                        print("Decoding error: \(error)")
                        return WeatherError.decodingError(error)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func createUrlComponents(for location: String) -> URLComponents {
        var components = URLComponents(string: Constants.weatherApiBaseUrl + Constants.forecastEndpoint)!
        
        components.queryItems = [
            URLQueryItem(name: "key", value: Constants.weatherApiKey),
            URLQueryItem(name: "q", value: location),
            URLQueryItem(name: "days", value: String(Constants.defaultDays)),
            URLQueryItem(name: "aqi", value: "no"),
            URLQueryItem(name: "alerts", value: "no")
        ]
        
        return components
    }
}


