import SwiftUI

struct GameDetailView: View {
    let game: Game
    let normalPrice: String?
    let salePrice: String?
    let discount: String?
    let steamRatingPercent: String?
    @State private var gameInfo: Game.GameInfo? = nil // Теперь gameInfo опциональный
    @State private var isLoading = true // Статус загрузки

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    ProgressView()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    // Если данные загружены
                    if let gameInfo = gameInfo {
                        // Изображение игры (из GameInfo)
                        if let imageUrl = gameInfo.imageUrl {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 250)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(15)
                                        .padding()
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 250)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(15)
                                        .padding()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 250)
                                        .frame(maxWidth: .infinity)
                                        .cornerRadius(15)
                                        .padding()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }

                        // Основная информация
                        VStack(alignment: .leading, spacing: 10) {
                            Text(game.title)
                                .font(.title)
                                .bold()
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal)

                            // Используем данные из каталога
                            HStack {
                                Text("Цена:")
                                    .font(.headline)
                                Spacer()
                                Text("\(normalPrice ?? "0") → \(salePrice ?? "0")")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .shadow(radius: 2)
                            .padding(.horizontal)

                            HStack {
                                Text("Скидка:")
                                    .font(.headline)
                                Spacer()
                                Text("\(discount ?? "0")%")
                            }
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .shadow(radius: 2)
                            .padding(.horizontal)

                            HStack {
                                Text("Рейтинг Steam:")
                                    .font(.headline)
                                Spacer()
                                Text("\(steamRatingPercent ?? "0")%")
                            }
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .shadow(radius: 2)
                            .padding(.horizontal)

                            if let developers = game.developers, !developers.isEmpty {
                                Text("Разработчики:")
                                    .font(.headline)
                                    .padding(.horizontal)
                                Text(developers.joined(separator: ", "))
                                    .padding(.horizontal)
                            }

                            // Жанры (из GameInfo)
                            if let genres = gameInfo.genres, !genres.isEmpty {
                                Text("Жанры:")
                                    .font(.headline)
                                    .padding(.horizontal)
                                Text(genres.joined(separator: ", "))
                                    .padding(.horizontal)
                            }

                            // Платформы (из GameInfo)
                            if let platforms = gameInfo.platforms, !platforms.isEmpty {
                                Text("Платформы:")
                                    .font(.headline)
                                    .padding(.horizontal)
                                Text(platforms.joined(separator: ", "))
                                    .padding(.horizontal)
                            }

                            if let steamLink = game.steamLink, let url = URL(string: steamLink) {
                                Link("Перейти в Steam", destination: url)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                    .padding(.top)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGroupedBackground))
                        .cornerRadius(15)
                        .shadow(radius: 3)
                    } else {
                        Text("Не удалось загрузить данные.")
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding()
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical)
            .onAppear {
                loadGameInfo()
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationBarTitle("Подробности игры", displayMode: .inline)
    }

    private func loadGameInfo() {
        // Загружаем данные о жанре, платформе и изображении
        Api().loadGameDetailsByName(gameName: game.title) { gameInfo in
            if let gameInfo = gameInfo {
                self.gameInfo = gameInfo
            }
            isLoading = false // Скрываем индикатор загрузки
        }
    }
}
