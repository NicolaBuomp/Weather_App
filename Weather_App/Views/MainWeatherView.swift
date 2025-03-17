import SwiftUI

struct MainWeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var showSearch = false
    
    var body: some View {
        ZStack {
            // Background gradient basato sull'ora del giorno
            backgroundGradient
            
            // Mostra un indicatore di caricamento durante il fetch dei dati
            if case .loading = viewModel.loadingState {
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            // Mostra un messaggio di errore se si verifica un problema
            else if case .error(let message) = viewModel.loadingState {
                VStack {
                    Text("Errore")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .foregroundColor(.white)
                        .padding()
                    
                    Button("Riprova") {
                        viewModel.search()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(15)
            }
            else if viewModel.weatherData != nil {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header con località e temperatura attuale
                        headerView
                        
                        // Dettagli meteo attuali
                        currentWeatherDetailsView
                        
                        // Previsione oraria
                        hourlyForecastView
                        
                        // Previsione per i prossimi giorni
                        dailyForecastView
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showSearch = true
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(Color.white)
                    }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSearch = true
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(Color.white)
                    }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSearch = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.white)
                    }
            }
        }
        .sheet(isPresented: $showSearch) {
            searchView
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // Definisce il gradiente di sfondo in base all'ora del giorno
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(
                colors: viewModel.isDaytime
                    ? [Color.blue, Color.cyan.opacity(0.8)]
                    : [Color.indigo, Color.black]
            ),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    // Header view con località e temperatura
    private var headerView: some View {
        VStack(spacing: 5) {
            Text(viewModel.weatherData?.location.name ?? "")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(viewModel.weatherData?.location.localtimeFormatted ?? "")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            HStack(alignment: .center) {
                if let iconURL = viewModel.currentConditionIconURL {
                    AsyncImage(url: iconURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                    } placeholder: {
                        ProgressView()
                    }
                }
                
                Text(viewModel.currentTemperature)
                    .font(.system(size: 70))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(viewModel.currentCondition)
                .font(.title2)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    // Vista dei dettagli meteo attuali
    private var currentWeatherDetailsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Dettagli")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                weatherDetailItem(icon: "thermometer", title: "Percepita", value: viewModel.feelsLikeTemperature)
                weatherDetailItem(icon: "humidity", title: "Umidità", value: viewModel.humidity)
                weatherDetailItem(icon: "wind", title: "Vento", value: viewModel.windSpeed)
                weatherDetailItem(icon: "safari", title: "Direzione", value: viewModel.windDirection)
                weatherDetailItem(icon: "cloud.rain", title: "Pioggia", value: viewModel.chanceOfRain)
                weatherDetailItem(icon: "sun.max", title: "UV", value: viewModel.uvIndex)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    // Elemento singolo di dettaglio meteo
    private func weatherDetailItem(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
    
    // Vista per la previsione oraria
    private var hourlyForecastView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Oggi")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.hourlyForecast) { hour in
                        VStack(spacing: 8) {
                            Text(hour.timeFormatted)
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            if let iconURL = hour.condition.iconUrl {
                                AsyncImage(url: iconURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                            
                            Text(String(format: "%.0f°", hour.tempC))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            // Questa è la parte importante: aggiungere sempre l'indicatore, anche con valore 0
                            HStack(spacing: 2) {
                                Image(systemName: "drop")
                                    .font(.system(size: 10))
                                // Mostra il valore della pioggia o 0% se non disponibile
                                Text("\(hour.chanceOfRain)%")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.blue)
                            // Opzionalmente, puoi nasconderlo visualmente ma mantenere lo spazio
                            .opacity(hour.chanceOfRain > 0 ? 1 : 0.3)
                        }
                        .frame(height: 130)  // Definisci un'altezza fissa per tutte le celle
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    // Vista per la previsione dei prossimi giorni
    private var dailyForecastView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Prossimi giorni")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(viewModel.forecastDays) { day in
                    HStack {
                        Text(day.dateFormatted)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if let iconURL = day.day.condition.iconUrl {
                            AsyncImage(url: iconURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                        
                        Text(day.day.condition.text)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 100, alignment: .leading)
                        
                        HStack(spacing: 10) {
                            Text(String(format: "%.0f°", day.day.mintempC))
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(String(format: "%.0f°", day.day.maxtempC))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    // Vista per la ricerca
    private var searchView: some View {
        VStack {
            Text("Cerca località")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            HStack {
                TextField("Inserisci città, regione o CAP", text: $viewModel.searchLocation)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Button("Cerca") {
                    viewModel.search()
                    showSearch = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        MainWeatherView()
    }
}
