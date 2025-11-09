//
//  SupplyItem.swift
//  DoctorHeliChecklistApp
//
//  ドクターヘリの物品データモデル
//

import Foundation

/// 物品項目を表すモデル
struct SupplyItem: Identifiable, Codable {
    var id: UUID
    var name: String                    // 物品名
    var category: String                // カテゴリ（医薬品、医療機器など）
    var isChecked: Bool                 // チェック状態
    var expirationDate: Date?           // 使用期限
    var quantity: Int                   // 数量
    var location: String                // 保管場所
    var notes: String                   // 備考
    var lastCheckedDate: Date?          // 最終チェック日時
    var rowIndex: Int?                  // スプレッドシートの行番号

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        isChecked: Bool = false,
        expirationDate: Date? = nil,
        quantity: Int = 0,
        location: String = "",
        notes: String = "",
        lastCheckedDate: Date? = nil,
        rowIndex: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.isChecked = isChecked
        self.expirationDate = expirationDate
        self.quantity = quantity
        self.location = location
        self.notes = notes
        self.lastCheckedDate = lastCheckedDate
        self.rowIndex = rowIndex
    }

    /// 使用期限が近いかチェック（30日以内）
    var isExpiringSoon: Bool {
        guard let expirationDate = expirationDate else { return false }
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        return expirationDate <= thirtyDaysFromNow && expirationDate >= Date()
    }

    /// 使用期限切れかチェック
    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return expirationDate < Date()
    }
}

/// 物品のカテゴリ
enum SupplyCategory: String, CaseIterable {
    case medicine = "医薬品"
    case medicalDevice = "医療機器"
    case consumable = "消耗品"
    case emergency = "緊急用品"
    case other = "その他"
}
