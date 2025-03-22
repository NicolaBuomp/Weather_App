//
//  FavoriteCitiesRepository.swift
//  Weather_App
//
//  Created by Nicola Buompane on 22/03/25.
//

import Foundation
import Combine

protocol FavoriteCitiesRepositoryProtocol {
    func getFavoriteCities() -> [FavoriteCity]
    func saveFavoriteCity(_ city: FavoriteCity) -> Bool
    func removeFavoriteCity(_ city: FavoriteCity) -> Bool
    func isCityFavorite(_ city: FavoriteCity) -> Bool
    func isCityFavorite(name: String, country: String) -> Bool
    
    // Nuovo metodo per cancellare tutti i dati salvati
    func clearFavorites() -> Bool
    
    var favoriteCitiesPublisher: AnyPublisher<[FavoriteCity], Never> { get }
}

class FavoriteCitiesRepository: FavoriteCitiesRepositoryProtocol {
    private let userDefaultsKey = "favoriteCities"
    private let favoriteCitiesSubject = CurrentValueSubject<[FavoriteCity], Never>([])
    
    var favoriteCitiesPublisher: AnyPublisher<[FavoriteCity], Never> {
        favoriteCitiesSubject.eraseToAnyPublisher()
    }
    
    init() {
        let cities = loadFavoriteCities()
        favoriteCitiesSubject.send(cities)
    }
    
    func getFavoriteCities() -> [FavoriteCity] {
        return favoriteCitiesSubject.value
    }
    
    func saveFavoriteCity(_ city: FavoriteCity) -> Bool {
        var cities = favoriteCitiesSubject.value
        // Evita duplicati: il confronto si basa sul contenuto
        guard !cities.contains(where: { $0 == city }) else {
            return false
        }
        cities.append(city)
        if saveFavoriteCities(cities) {
            favoriteCitiesSubject.send(cities)
            return true
        }
        return false
    }
    
    func removeFavoriteCity(_ city: FavoriteCity) -> Bool {
        var cities = favoriteCitiesSubject.value
        // Rimuove la città basandosi sul confronto dei dati
        cities.removeAll(where: { $0 == city })
        if saveFavoriteCities(cities) {
            favoriteCitiesSubject.send(cities)
            return true
        }
        return false
    }
    
    func isCityFavorite(_ city: FavoriteCity) -> Bool {
        let cities = favoriteCitiesSubject.value
        return cities.contains(where: { $0 == city })
    }
    
    func isCityFavorite(name: String, country: String) -> Bool {
        let cities = favoriteCitiesSubject.value
        return cities.contains(where: { $0.name == name && $0.country == country })
    }
    
    // Metodo per cancellare tutti i preferiti
    func clearFavorites() -> Bool {
        let empty: [FavoriteCity] = []
        if saveFavoriteCities(empty) {
            favoriteCitiesSubject.send(empty)
            return true
        }
        return false
    }
    
    // MARK: - Metodi Privati
    
    private func loadFavoriteCities() -> [FavoriteCity] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return []
        }
        do {
            let cities = try JSONDecoder().decode([FavoriteCity].self, from: data)
            return cities
        } catch {
            print("Errore nel caricamento delle città preferite: \(error)")
            return []
        }
    }
    
    private func saveFavoriteCities(_ cities: [FavoriteCity]) -> Bool {
        do {
            let data = try JSONEncoder().encode(cities)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            return true
        } catch {
            print("Errore nel salvataggio delle città preferite: \(error)")
            return false
        }
    }
}
