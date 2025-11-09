//
//  GoogleSheetsService.swift
//  DoctorHeliChecklistApp
//
//  Google Sheets API との連携サービス
//

import Foundation

/// Google Sheets との同期サービス
class GoogleSheetsService: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?

    private let baseURL = "https://sheets.googleapis.com/v4/spreadsheets"
    private var spreadsheetId: String?
    private var apiKey: String?

    /// スプレッドシートIDとAPIキーを設定
    func configure(spreadsheetId: String, apiKey: String) {
        self.spreadsheetId = spreadsheetId
        self.apiKey = apiKey
        self.isConnected = true
    }

    /// スプレッドシートから物品データを読み込み
    func fetchSupplyItems(completion: @escaping (Result<[SupplyItem], Error>) -> Void) {
        guard let spreadsheetId = spreadsheetId,
              let apiKey = apiKey else {
            completion(.failure(NSError(domain: "GoogleSheetsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "設定が未完了です"])))
            return
        }

        let range = "A2:H1000" // ヘッダー行を除く
        let urlString = "\(baseURL)/\(spreadsheetId)/values/\(range)?key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "GoogleSheetsService", code: 2, userInfo: [NSLocalizedDescriptionKey: "無効なURL"])))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "GoogleSheetsService", code: 3, userInfo: [NSLocalizedDescriptionKey: "データがありません"])))
                }
                return
            }

            do {
                let response = try JSONDecoder().decode(SheetsResponse.self, from: data)
                let items = self.parseSupplyItems(from: response.values)
                DispatchQueue.main.async {
                    self.lastSyncDate = Date()
                    completion(.success(items))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    /// スプレッドシートを更新
    func updateSupplyItem(_ item: SupplyItem, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let spreadsheetId = spreadsheetId,
              let apiKey = apiKey,
              let rowIndex = item.rowIndex else {
            completion(.failure(NSError(domain: "GoogleSheetsService", code: 4, userInfo: [NSLocalizedDescriptionKey: "更新情報が不足しています"])))
            return
        }

        let range = "A\(rowIndex):H\(rowIndex)"
        let values = itemToRowValues(item)

        // Google Sheets API の更新リクエストを構築
        let updateData: [String: Any] = [
            "values": [values]
        ]

        let urlString = "\(baseURL)/\(spreadsheetId)/values/\(range)?valueInputOption=RAW&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "GoogleSheetsService", code: 5, userInfo: [NSLocalizedDescriptionKey: "無効なURL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: updateData)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            DispatchQueue.main.async {
                self.lastSyncDate = Date()
                completion(.success(()))
            }
        }.resume()
    }

    // MARK: - Private Methods

    private func parseSupplyItems(from values: [[String]]?) -> [SupplyItem] {
        guard let values = values else { return [] }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"

        return values.enumerated().compactMap { index, row in
            guard row.count >= 3 else { return nil }

            let name = row[0]
            let category = row[1]
            let isChecked = row.count > 2 ? (row[2].lowercased() == "true" || row[2] == "✓") : false
            let expirationDate = row.count > 3 ? dateFormatter.date(from: row[3]) : nil
            let quantity = row.count > 4 ? Int(row[4]) ?? 0 : 0
            let location = row.count > 5 ? row[5] : ""
            let notes = row.count > 6 ? row[6] : ""
            let lastChecked = row.count > 7 ? dateFormatter.date(from: row[7]) : nil

            return SupplyItem(
                name: name,
                category: category,
                isChecked: isChecked,
                expirationDate: expirationDate,
                quantity: quantity,
                location: location,
                notes: notes,
                lastCheckedDate: lastChecked,
                rowIndex: index + 2 // ヘッダー行があるため+2
            )
        }
    }

    private func itemToRowValues(_ item: SupplyItem) -> [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"

        return [
            item.name,
            item.category,
            item.isChecked ? "✓" : "",
            item.expirationDate.map { dateFormatter.string(from: $0) } ?? "",
            String(item.quantity),
            item.location,
            item.notes,
            item.lastCheckedDate.map { dateFormatter.string(from: $0) } ?? ""
        ]
    }
}

// MARK: - Response Models

struct SheetsResponse: Codable {
    let values: [[String]]?
}
