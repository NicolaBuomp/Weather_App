import SwiftUI

struct FavoriteCityView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: FavoriteCitiesViewModel
    
    init(weatherViewModel: WeatherViewModel) {
        _viewModel = StateObject(wrappedValue: FavoriteCitiesViewModel(weatherViewModel: weatherViewModel))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                if viewModel.favoriteCities.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.favoriteCities) { city in
                                favoriteCityCard(for: city)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Città Preferite")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: Binding<FavoriteCitiesAlertItem?>(
            get: { viewModel.errorMessage.map { FavoriteCitiesAlertItem(message: $0) } },
            set: { _ in viewModel.errorMessage = nil }
        )) { alertItem in
            Alert(
                title: Text("Errore"),
                message: Text(alertItem.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .toolbar {
            // Pulsante per cancellare TUTTI i preferiti
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.clearFavorites()
                }) {
                    Image(systemName: "trash")
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash")
                .font(.system(size: 70))
                .foregroundColor(.white.opacity(0.7))
                .padding()
            Text("Nessuna città preferita")
                .font(.title2)
                .foregroundColor(.white)
            Text("Aggiungi le tue città preferite utilizzando l'icona a forma di stella nella pagina del meteo.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func favoriteCityCard(for city: FavoriteCity) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(city.name)
                    .font(.headline)
                Text(city.country)
                    .font(.subheadline)
            }
            Spacer()
            HStack(spacing: 16) {
                Button(action: {
                    viewModel.selectCity(city: city)
                    dismiss()
                }) {
                    Image(systemName: "location.magnifyingglass")
                        .font(.system(size: 18))
                }
                .buttonStyle(CircleButtonStyle())
                Button(action: {
                    withAnimation {
                        viewModel.removeFavoriteCity(city: city)
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
                .buttonStyle(CircleButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.1))
        )
        .transition(.opacity.combined(with: .scale))
    }
}

struct CircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(10)
            .background(
                Circle()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.3 : 0.2))
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct FavoriteCitiesAlertItem: Identifiable {
    var id = UUID()
    let message: String
}

#Preview {
    NavigationStack {
        FavoriteCityView(weatherViewModel: WeatherViewModel())
    }
}
