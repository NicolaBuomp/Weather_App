//
//  FavoriteCity.swift
//  Weather_App
//
//  Created by Nicola Buompane on 22/03/25.
//

import Foundation

struct FavoriteCity: Codable, Identifiable, Equatable {
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double

    // Identificatore calcolato basato sui dati della città
    var id: String {
        return "\(name)-\(country)-\(latitude)-\(longitude)"
    }
    
    var displayName: String {
        return "\(name), \(country)"
    }
    
    var coordinates: String {
        return "\(latitude),\(longitude)"
    }
    
    init(name: String, country: String, latitude: Double, longitude: Double) {
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // Inizializzatore da LocationSuggestion
    init(from suggestion: LocationSuggestion) {
        self.name = suggestion.name
        self.country = suggestion.country
        self.latitude = suggestion.latitude
        self.longitude = suggestion.longitude
    }
    
    // Due città sono uguali se hanno gli stessi dati (ignorando l'ID)
    static func == (lhs: FavoriteCity, rhs: FavoriteCity) -> Bool {
        return lhs.name == rhs.name &&
               lhs.country == rhs.country &&
               lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude
    }
    
    // Verifica se la città corrisponde a una LocationSuggestion
    func matches(_ suggestion: LocationSuggestion) -> Bool {
        return name == suggestion.name &&
               country == suggestion.country &&
               latitude == suggestion.latitude &&
               longitude == suggestion.longitude
    }
}
