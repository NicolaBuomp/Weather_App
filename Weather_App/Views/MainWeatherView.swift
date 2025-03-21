import SwiftUI

struct MainWeatherView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @StateObject private var locationSearchViewModel = LocationSearchViewModel()
    @State private var scrollOffset: CGFloat = 0
    
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
            } else if viewModel.weatherData != nil {
                // IMPORTANTE: Approccio per rilevare lo scroll con animazioni migliorate
                ScrollViewOffset { offset in
                    // Aggiorniamo lo scrollOffset con l'offset attuale
                    scrollOffset = offset
                } content: {
                    VStack(spacing: 15) {
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
                    Text(viewModel.weatherData?.location.name ?? "")
                    .font(.system(size: 35))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    NavigationLink(destination: SearchWeatherView(viewModel: viewModel)) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    NavigationLink(destination: FavoriteCityView()) {
                        Image(systemName: "list.star")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            let standardAppearance = UINavigationBarAppearance()
            standardAppearance.configureWithTransparentBackground()
            
            // Sfumatura sottile nella navigation bar quando si scorre
            standardAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            standardAppearance.shadowColor = .clear
            
            // Navigation bar completamente trasparente all'inizio
            let scrollEdgeAppearance = UINavigationBarAppearance()
            scrollEdgeAppearance.configureWithTransparentBackground()
            scrollEdgeAppearance.shadowColor = .clear
            
            UINavigationBar.appearance().standardAppearance = standardAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
            UINavigationBar.appearance().compactAppearance = standardAppearance
        }
    }
    
    // Definisce il gradiente di sfondo in base all'ora del giorno
    private var backgroundGradient: some View {
        ZStack {
            // Gradiente base
            LinearGradient(
                        gradient: Gradient(
                            colors: viewModel.isDaytime
                                ? [Color.blue.opacity(0.7), Color(red: 0.29, green: 0.57, blue: 1.0)]
                                : [Color(red: 0.08, green: 0.12, blue: 0.19), Color(red: 0.14, green: 0.23, blue: 0.33)]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
            // Overlay con sfumature per aggiungere profondità
            GeometryReader { geo in
                        ZStack {
                            // Overlay radiale per la parte superiore (simulazione sole/luna)
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    viewModel.isDaytime
                                        ? Color.yellow.opacity(0.2)
                                        : Color.white.opacity(0.05),
                                    Color.clear
                                ]),
                                center: .topTrailing,
                                startRadius: 0,
                                endRadius: geo.size.width * 0.8
                            )
                            
                            // Particelle leggere / stelle
                            if !viewModel.isDaytime {
                                ForEach(0..<30) { i in
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: CGFloat.random(in: 1...2), height: CGFloat.random(in: 1...2))
                                        .position(
                                            x: CGFloat.random(in: 0...geo.size.width),
                                            y: CGFloat.random(in: 0...geo.size.height/2)
                                        )
                                        .opacity(Double.random(in: 0.3...0.7))
                                }
                            }
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
    }
    
    private var headerView: some View {
        VStack(spacing: 5) {
            HStack() {
                if let iconURL = viewModel.currentConditionIconURL {
                    AsyncImage(url: iconURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 0)
                    } placeholder: {
                        ProgressView()
                    }
                }
                
                Text(viewModel.currentTemperature)
                    .font(.system(size: 70))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
            
            Text(viewModel.currentCondition)
                .font(.title2)
                .foregroundColor(.white)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
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
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                
                // Leggero bordo lucido
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.3), .white.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        )
        .cornerRadius(15)
    }
    
    // Elemento singolo di dettaglio meteo
    private func weatherDetailItem(icon: String, title: String, value: String) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .transition(.scale.combined(with: .opacity))
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
                            
                            // Indicatore pioggia
                            HStack(spacing: 2) {
                                Image(systemName: "drop")
                                    .font(.system(size: 10))
                                Text("\(hour.chanceOfRain)%")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.blue)
                            .opacity(hour.chanceOfRain > 0 ? 1 : 0.3)
                        }
                        .frame(height: 130)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                    }
                }
                .padding(.bottom, 5) // Aggiunto per evitare che l'ombra venga tagliata
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                
                // Leggero bordo lucido
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.3), .white.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        )
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
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                }
            }
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                
                // Leggero bordo lucido
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.3), .white.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        )
        .cornerRadius(15)
    }
}

// STRUTTURE DI SUPPORTO

struct ScrollViewOffset<Content: View>: View {
    let onOffsetChange: (CGFloat) -> Void
    let content: () -> Content
    
    init(onOffsetChange: @escaping (CGFloat) -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.onOffsetChange = onOffsetChange
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .global).minY)
                        .frame(height: 0)
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            // Aggiungiamo un leggero smoothing all'offset per animazioni più morbide
                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1)) {
                                onOffsetChange(value)
                            }
                        }
                }
                .frame(height: 0)
                
                content()
            }
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        MainWeatherView(viewModel: WeatherViewModel())
    }
}
