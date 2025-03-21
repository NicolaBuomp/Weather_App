//
//  SearchWeatherView.swift
//  Weather_App
//
//  Created by Nicola Buompane on 21/03/25.
//

import SwiftUI

struct SearchWeatherView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: WeatherViewModel
    @StateObject private var locationSearchViewModel = LocationSearchViewModel()
    var body: some View {
        VStack {
            HStack {
                TextField("Inserisci città, regione o CAP", text: $locationSearchViewModel.searchText)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Button("Cerca") {
                    viewModel.searchLocation = locationSearchViewModel.searchText
                    viewModel.search()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            if locationSearchViewModel.isSearching {
                ProgressView()
                    .padding()
            } else if !locationSearchViewModel.suggestions.isEmpty {
                List(locationSearchViewModel.suggestions) { suggestion in
                Button(action: {
                    viewModel.searchLocation = suggestion.displayName
                    viewModel.search()
                    dismiss()
                }) {
                        VStack(alignment: .leading) {
                            Text(suggestion.name)
                                .font(.headline)
                            Text(suggestion.country)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    SearchWeatherView(viewModel: WeatherViewModel())
}
