import Foundation
import SwiftUI

// Модель данных для игры
struct Game: Codable, Identifiable {
    let id = UUID()
    var title: String
    var normalPrice: String
    var salePrice: String
    var steamRatingPercent: String
    var thumb: String
    var description: String? // Добавлено описание
    var steamLink: String? // Добавлена ссылка на Steam
    
    var discount: Double {
        let normal = Double(normalPrice) ?? 0
        let sale = Double(salePrice) ?? 0
        return normal > 0 ? ((normal - sale) / normal) * 100 : 0
    }
}

struct GameSearchResponse: Codable {
    let results: [GameDetails]
}

struct GameDetails: Codable {
    let id: String
    let name: String
    let background_image: String
}

class Api: ObservableObject {
    @Published var games = [Game]()
    
    // В функции загрузки данных
    func loadData(url: String, completion: @escaping ([Game]) -> Void) {
        print("Загружаю данные с URL: \(url)")  // Это сообщение должно появиться в консоли
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
    
    func loadGameDetailsByName(gameName: String, completion: @escaping (Game?) -> Void) {
        let urlString = "https://api.rawg.io/api/games?key=e95f38270cc2497c8b714ee0d35f1ca9&search=\(gameName)"
        guard let url = URL(string: urlString) else {
            print("Неверный URL")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
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
            
            // Выводим весь JSON-ответ для отладки
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Ответ API: \(jsonString)")
            }
            
            do {
                // Декодируем JSON в структуру GameSearchResponse
                let decodedResponse = try JSONDecoder().decode(GameSearchResponse.self, from: data)
                if let firstGame = decodedResponse.results.first {
                    // Получаем ID игры и передаем в loadGameDetails
                    // Явно указываем self, чтобы избежать циклов сильных ссылок
                    self?.loadGameDetails(gameId: firstGame.id, completion: completion)
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

    
    // Функция загрузки деталей игры с обработкой ошибки "Not found"
    func loadGameDetails(gameId: String, completion: @escaping (Game?) -> Void) {
        print("Загружаю данные для игры с ID: \(gameId)")  // Добавим вывод ID
        let urlString = "https://api.rawg.io/api/games/\(gameId)?key=e95f38270cc2497c8b714ee0d35f1ca9"
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
            
            // Выводим весь JSON-ответ для отладки
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Ответ API: \(jsonString)")
            }
            
            // Проверяем на ошибку "Not found"
            if let json = try? JSONSerialization.jsonObject(with: data, options: []),
               let jsonResponse = json as? [String: Any], jsonResponse["detail"] != nil {
                print("Ошибка: данные не найдены для игры с ID \(gameId)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Декодируем ответ в объект Game
            do {
                let gameDetails = try JSONDecoder().decode(Game.self, from: data)
                DispatchQueue.main.async {
                    completion(gameDetails)
                }
            } catch {
                print("Ошибка декодирования JSON: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}
