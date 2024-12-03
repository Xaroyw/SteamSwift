import SwiftUI

struct GameDetailView: View {
    let game: Game
    @State private var detailedGame: Game? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let detailedGame = detailedGame {
                    RemoteImage(url: detailedGame.thumb)
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding()

                    Text(detailedGame.title)
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal)

                    Text("Цена: \(detailedGame.normalPrice)$ → \(detailedGame.salePrice)$")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.horizontal)

                    Text("Скидка: \(String(format: "%.0f", detailedGame.discount))%")
                        .padding(.horizontal)

                    Text("Рейтинг: \(detailedGame.steamRatingPercent)%")
                        .padding(.horizontal)

                    // Описание игры
                    if let description = detailedGame.description {
                        Text(description)
                            .padding(.horizontal)
                    } else {
                        Text("Описание не доступно")
                            .padding(.horizontal)
                            .foregroundColor(.gray)
                    }

                    // Кнопка для перехода в Steam
                    if let steamLink = detailedGame.steamLink, let url = URL(string: steamLink) {
                        Link("Перейти в Steam", destination: url)
                            .padding()
                            .foregroundColor(.blue)
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    } else {
                        Text("Ссылка на Steam не доступна")
                            .padding(.horizontal)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                } else {
                    Text("Загружается информация о игре...")
                        .padding()
                }
            }
        }
        .navigationTitle("Описание игры")
        .onAppear {
            Api().loadGameDetails(gameId: game.id.uuidString) { gameDetails in
                self.detailedGame = gameDetails
            }
        }
    }
}
