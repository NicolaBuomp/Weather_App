import SwiftUI

@main
struct WeatherApp: App {
    @StateObject var viewModel = WeatherViewModel()
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainWeatherView(viewModel: viewModel)
            }
        }
    }
}
