import SwiftUI

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 14 Pro") // Укажите желаемую модель устройства
    }
}

struct ContentView: View {
    @State var games = [Game]()
    @State private var searchQuery = ""
    @State private var filteredGames = [Game]()
    @State private var noGamesFound = false

    @State private var minRating: Double = 0 // Минимальный рейтинг для фильтра
    @State private var maxPrice: Double = 100 // Максимальная цена для фильтра
    @State private var selectedSortOption: SortOption = .ratingHighToLow // Выбранная сортировка

    var body: some View {
        NavigationView {
            VStack {
                // Поле для поиска
                TextField("Введите название игры", text: $searchQuery)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: searchQuery) { _ in
                        filterAndSortGames()
                    }
                    .padding()

                // Фильтры
                HStack {
                    VStack {
                        Text("Мин. рейтинг: \(Int(minRating))%")
                        Slider(value: $minRating, in: 0...100, step: 5)
                            .onChange(of: minRating) { _ in
                                filterAndSortGames()
                            }
                    }
                    .padding()

                    VStack {
                        Text("Макс. цена: \(String(format: "%.2f", maxPrice))$")
                        Slider(value: $maxPrice, in: 0...10, step: 1)
                            .onChange(of: maxPrice) { _ in
                                filterAndSortGames()
                            }
                    }
                    .padding()
                }

                // Кнопка для сортировки
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            selectedSortOption = option
                            filterAndSortGames()
                        }
                    }
                } label: {
                    Text("Сортировка: \(selectedSortOption.rawValue)")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.bottom)

                // Проверка наличия игр
                if noGamesFound {
                    Text("Подходящие игры не найдены.")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // Список игр
                    List(filteredGames) { game in
                        NavigationLink(destination: GameDetailView(game: game)) { // Переход к странице игры
                            HStack(spacing: 20) {
                                RemoteImage(url: game.thumb)
                                    .frame(width: 100, height: 50)
                                    .cornerRadius(8)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(game.title).bold()
                                    Text("Цена: \(game.normalPrice)$ → \(game.salePrice)$").foregroundColor(.red)
                                    Text("Скидка: \(String(format: "%.0f", game.discount))%")
                                    Text("Рейтинг: \(game.steamRatingPercent)%")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Каталог игр")
            .onAppear {
                Api().loadData(url: "https://www.cheapshark.com/api/1.0/deals?storeID=1&upperPrice=200") { games in
                    self.games = games
                    filterAndSortGames()
                }
            }
        }
    }

    private func filterAndSortGames() {
        // Фильтрация игр по рейтингу и цене, а также по названию, если searchQuery не пуст
        filteredGames = games.filter { game in
            let matchesRating = (Double(game.steamRatingPercent) ?? 0) >= minRating
            let matchesPrice = (Double(game.salePrice) ?? 0) <= maxPrice
            
            // Если поиск пустой, игнорируем фильтрацию по названию
            if searchQuery.isEmpty {
                return matchesRating && matchesPrice
            } else {
                let matchesSearchQuery = game.title.lowercased().contains(searchQuery.lowercased()) // Фильтрация по поисковому запросу
                return matchesRating && matchesPrice && matchesSearchQuery
            }
        }

        // Применяем сортировку
        switch selectedSortOption {
        case .ratingLowToHigh:
            filteredGames.sort { (Double($0.steamRatingPercent) ?? 0) < (Double($1.steamRatingPercent) ?? 0) }
        case .ratingHighToLow:
            filteredGames.sort { (Double($0.steamRatingPercent) ?? 0) > (Double($1.steamRatingPercent) ?? 0) }
        case .priceLowToHigh:
            filteredGames.sort { (Double($0.salePrice) ?? 0) < (Double($1.salePrice) ?? 0) }
        case .priceHighToLow:
            filteredGames.sort { (Double($0.salePrice) ?? 0) > (Double($1.salePrice) ?? 0) }
        }

        noGamesFound = filteredGames.isEmpty
    }
}

// Варианты сортировки
enum SortOption: String, CaseIterable {
    case ratingLowToHigh = "Рейтинг (по возрастанию)"
    case ratingHighToLow = "Рейтинг (по убыванию)"
    case priceLowToHigh = "Цена (по возрастанию)"
    case priceHighToLow = "Цена (по убыванию)"
}


// Компонент для загрузки изображений с URL
struct RemoteImage: View {
    @StateObject private var loader: ImageLoader
    var placeholder: Image

    init(url: String, placeholder: Image = Image(systemName: "photo")) {
        _loader = StateObject(wrappedValue: ImageLoader(url: url))
        self.placeholder = placeholder
    }

    var body: some View {
        if let image = loader.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
                .resizable()
                .scaledToFill()
                .onAppear {
                    loader.load()
                }
        }
    }
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private let url: String

    init(url: String) {
        self.url = url
    }

    func load() {
        guard let url = URL(string: url) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = uiImage
                }
            } else if let error = error {
                print("Ошибка загрузки изображения: \(error.localizedDescription)")
            }
        }.resume()
    }
}
