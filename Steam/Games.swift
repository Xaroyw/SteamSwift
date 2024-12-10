import Foundation
import SwiftUI

// Модель данных для игры, включая подробности
struct Game: Codable, Identifiable {
    let id = UUID()
    var title: String
    var normalPrice: String?
    var salePrice: String?
    var steamRatingPercent: String?
    var thumb: String
    var description: String? // Описание игры
    var steamLink: String? // Ссылка на Steam
    var genres: [String]?  // Жанры игры
    let developers: [String]? // Добавлено поле для разработчиков
    var platforms: [String]? // Платформы
    var price: String?  // Цена для отображения через CheapShark
    var priceInfo: PriceInfo?
    
    var discount: Double? {
        guard let normalPriceString = normalPrice,
              let salePriceString = salePrice,
              let normal = Double(normalPriceString),
              let sale = Double(salePriceString) else { return nil }
        return normal > 0 ? ((normal - sale) / normal) * 100 : 0
    }

    // Модель для жанра, платформы и изображения
    struct GameInfo {
        var genres: [String]?
        var platforms: [String]?
        var imageUrl: String?
    }
    
    struct PriceInfo: Decodable, Encodable {
        var normalPrice: String
        var salePrice: String
        var discount: Double
    }

    // Реализация encode(to:) для Game, чтобы соответствовать протоколу Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(normalPrice, forKey: .normalPrice)
        try container.encode(salePrice, forKey: .salePrice)
        try container.encode(steamRatingPercent, forKey: .steamRatingPercent)
        try container.encode(thumb, forKey: .thumb)
        try container.encode(description, forKey: .description)
        try container.encode(steamLink, forKey: .steamLink)
        try container.encode(genres, forKey: .genres)
        try container.encode(developers, forKey: .developers)
        try container.encode(platforms, forKey: .platforms)
        try container.encode(price, forKey: .price)
        try container.encode(priceInfo, forKey: .priceInfo)
    }

    // Кодовые ключи для кодирования
    enum CodingKeys: String, CodingKey {
        case title, normalPrice, salePrice, steamRatingPercent, thumb, description, steamLink, genres, developers, platforms, price, priceInfo
    }
}

// Модель для деталей игры из RAWG
struct GameDetails: Codable {
    let id: Int
    let name: String
    let background_image: String?
    let description: String?
    let genres: [Genre]?
    let platforms: [Platform]?
    let developers: [Developer]? // Добавлено поле для разработчиков
    let steamLink: String?

    struct Genre: Codable {
        let name: String
    }

    struct Platform: Codable {
        let platform: PlatformDetails
    }
    
    struct PlatformDetails: Codable {
        let name: String
    }
    
    struct Developer: Codable {
        let name: String
    }
}

// Ответ от API для поиска игр по имени
struct GameSearchResponse: Codable {
    let results: [GameDetails]
}

class Api: ObservableObject {
    @Published var games = [Game]()
    
    // Загрузка данных с URL
    func loadData(url: String, completion: @escaping ([Game]) -> Void) {
        print("Загружаю данные с URL: \(url)")
        guard let url = URL(string: url) else {
            print("Неверный URL")
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let games = try JSONDecoder().decode([Game].self, from: data)
                    DispatchQueue.main.async {
                        completion(games)
                    }
                } catch {
                    print("Ошибка декодирования JSON: \(error)")
                }
            } else if let error = error {
                print("Ошибка загрузки данных: \(error)")
            }
        }.resume()
    }
    
    func loadGameDetailsByName(gameName: String, completion: @escaping (Game.GameInfo?) -> Void) {
        let encodedGameName = gameName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? gameName
        let urlString = "https://api.rawg.io/api/games?key=e95f38270cc2497c8b714ee0d35f1ca9&search=\(encodedGameName)"
        
        guard let url = URL(string: urlString) else {
            print("Неверный URL")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Ошибка загрузки данных: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            guard let data = data else {
                print("Нет данных в ответе")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(GameSearchResponse.self, from: data)
                if let firstGame = decodedResponse.results.first {
                    // Извлекаем только необходимые поля: жанры, платформы и изображение
                    let genres = firstGame.genres?.map { $0.name } ?? []
                    let platforms = firstGame.platforms?.compactMap { $0.platform.name } ?? []
                    let imageUrl = firstGame.background_image
                    
                    // Заполняем структуру GameInfo с этими данными
                    let gameInfo = Game.GameInfo(genres: genres, platforms: platforms, imageUrl: imageUrl)
                    
                    DispatchQueue.main.async {
                        completion(gameInfo)
                    }
                } else {
                    print("Игра не найдена")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                print("Ошибка декодирования JSON: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }



    // Метод для получения цен и скидок через CheapShark API
    func loadCheapSharkPrices(gameName: String, completion: @escaping (String?, String?) -> Void) {
        let encodedGameName = gameName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? gameName
        let urlString = "https://api.cheapshark.com/api/1.0/games?title=\(encodedGameName)"
        
        guard let url = URL(string: urlString) else {
            print("Неверный URL")
            completion(nil, nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Ошибка загрузки данных: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
                return
            }
            
            guard let data = data else {
                print("Нет данных в ответе")
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
                return
            }
            
            // Логируем весь ответ от API
            print("Ответ от CheapShark API: \(String(data: data, encoding: .utf8) ?? "Не удалось декодировать ответ")")
            
            do {
                // Декодируем JSON и извлекаем цену и скидку
                if let decodedResponse = try? JSONDecoder().decode([CheapSharkGame].self, from: data), let game = decodedResponse.first {
                    // Логируем данные
                    print("Получены данные из CheapShark: \(game.normalPrice), \(game.salePrice)")
                    DispatchQueue.main.async {
                        completion(game.normalPrice, game.salePrice)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil, nil)
                    }
                }
            } catch {
                print("Ошибка декодирования JSON: \(error)")
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
            }
        }.resume()
    }
}

// Структура для обработки ответа от CheapShark API
struct CheapSharkGame: Codable {
    let normalPrice: String
    let salePrice: String
}
