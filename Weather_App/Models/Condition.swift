import Foundation

struct Condition: Codable {
    let text: String
    let icon: String
    let code: Int
    
    // Metodo per ottenere l'URL completo dell'icona
    var iconUrl: URL? {
        // L'API fornisce URL relativi come "//cdn.weatherapi.com/weather/64x64/day/113.png"
        // Li converto in URL assoluti
        if let url = URL(string: "https:\(icon)") {
            return url
        }
        return nil
    }
}
