//
//  ChecklistViewModel.swift
//  DoctorHeliChecklistApp
//
//  チェックリストのビジネスロジックを管理
//

import Foundation
import SwiftUI

class ChecklistViewModel: ObservableObject {
    @Published var items: [SupplyItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let sheetsService = GoogleSheetsService()

    private let userDefaults = UserDefaults.standard
    private let itemsKey = "SavedSupplyItems"

    init() {
        loadFromLocal()
    }

    /// ローカルストレージから読み込み
    func loadFromLocal() {
        if let data = userDefaults.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([SupplyItem].self, from: data) {
            self.items = decoded
        } else {
            // 初期サンプルデータ
            loadSampleData()
        }
    }

    /// ローカルストレージに保存
    func saveToLocal() {
        if let encoded = try? JSONEncoder().encode(items) {
            userDefaults.set(encoded, forKey: itemsKey)
        }
    }

    /// Google Sheets から読み込み
    func loadItems() {
        if sheetsService.isConnected {
            syncWithSheets()
        } else {
            loadFromLocal()
        }
    }

    /// Google Sheets と同期
    func syncWithSheets() {
        isLoading = true
        errorMessage = nil

        sheetsService.fetchSupplyItems { [weak self] result in
            guard let self = self else { return }

            self.isLoading = false

            switch result {
            case .success(let items):
                self.items = items
                self.saveToLocal()
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                // エラー時はローカルデータを使用
                self.loadFromLocal()
            }
        }
    }

    /// チェック状態をトグル
    func toggleCheck(_ item: SupplyItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isChecked.toggle()
            items[index].lastCheckedDate = items[index].isChecked ? Date() : nil
            updateItem(items[index])
        }
    }

    /// 物品を更新
    func updateItem(_ item: SupplyItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveToLocal()

            // Google Sheets に同期
            if sheetsService.isConnected {
                sheetsService.updateSupplyItem(item) { result in
                    switch result {
                    case .success:
                        print("✓ Google Sheets に同期しました")
                    case .failure(let error):
                        print("⚠️ 同期エラー: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    /// 物品を追加
    func addItem(_ item: SupplyItem) {
        items.append(item)
        saveToLocal()

        // Google Sheets に同期（新規行追加）
        if sheetsService.isConnected {
            // 注意: 新規追加は別途 append API を使用する必要があります
            syncWithSheets() // 一旦全体を再読み込み
        }
    }

    /// 物品を削除
    func deleteItem(_ item: SupplyItem) {
        items.removeAll { $0.id == item.id }
        saveToLocal()
    }

    /// サンプルデータを読み込み
    private func loadSampleData() {
        let calendar = Calendar.current
        let today = Date()

        items = [
            SupplyItem(
                name: "エピネフリン注射液",
                category: "医薬品",
                isChecked: false,
                expirationDate: calendar.date(byAdding: .month, value: 6, to: today),
                quantity: 5,
                location: "救急薬品箱A",
                notes: "アナフィラキシーショック用"
            ),
            SupplyItem(
                name: "生理食塩水500ml",
                category: "医薬品",
                isChecked: true,
                expirationDate: calendar.date(byAdding: .year, value: 2, to: today),
                quantity: 10,
                location: "輸液保管庫",
                notes: "",
                lastCheckedDate: today
            ),
            SupplyItem(
                name: "AED",
                category: "医療機器",
                isChecked: true,
                expirationDate: calendar.date(byAdding: .day, value: 15, to: today),
                quantity: 1,
                location: "機内右側",
                notes: "バッテリーチェック必要",
                lastCheckedDate: today
            ),
            SupplyItem(
                name: "気管挿管チューブ（7.5mm）",
                category: "医療機器",
                isChecked: false,
                expirationDate: nil,
                quantity: 3,
                location: "気道確保セット",
                notes: ""
            ),
            SupplyItem(
                name: "滅菌ガーゼ",
                category: "消耗品",
                isChecked: false,
                expirationDate: calendar.date(byAdding: .month, value: 3, to: today),
                quantity: 50,
                location: "消耗品棚",
                notes: "在庫少なくなったら補充"
            ),
            SupplyItem(
                name: "ディスポ手袋（Mサイズ）",
                category: "消耗品",
                isChecked: true,
                expirationDate: nil,
                quantity: 100,
                location: "消耗品棚",
                notes: "",
                lastCheckedDate: today
            ),
            SupplyItem(
                name: "酸素ボンベ",
                category: "緊急用品",
                isChecked: false,
                expirationDate: calendar.date(byAdding: .year, value: 1, to: today),
                quantity: 2,
                location: "機内後部",
                notes: "圧力チェック必須"
            ),
            SupplyItem(
                name: "救急バッグ",
                category: "緊急用品",
                isChecked: true,
                expirationDate: nil,
                quantity: 1,
                location: "機内中央",
                notes: "中身の定期点検実施済み",
                lastCheckedDate: today
            )
        ]
        saveToLocal()
    }
}
