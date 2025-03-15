import Foundation

struct WeatherResponse: Decodable {
    let location: Location
    let current: Current
    let forecast: Forecast
}
