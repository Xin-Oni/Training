//
//  ItemDetailView.swift
//  DoctorHeliChecklistApp
//
//  物品の詳細編集画面
//

import SwiftUI

struct ItemDetailView: View {
    @Binding var item: SupplyItem
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDatePicker = false

    var body: some View {
        Form {
            Section(header: Text("基本情報")) {
                TextField("物品名", text: $item.name)

                Picker("カテゴリ", selection: $item.category) {
                    ForEach(["医薬品", "医療機器", "消耗品", "緊急用品", "その他"], id: \.self) { category in
                        Text(category).tag(category)
                    }
                }

                Stepper("数量: \(item.quantity)", value: $item.quantity, in: 0...9999)

                TextField("保管場所", text: $item.location)
            }

            Section(header: Text("使用期限")) {
                Toggle("使用期限を設定", isOn: Binding(
                    get: { item.expirationDate != nil },
                    set: { newValue in
                        if newValue {
                            item.expirationDate = Date()
                        } else {
                            item.expirationDate = nil
                        }
                    }
                ))

                if item.expirationDate != nil {
                    DatePicker(
                        "使用期限",
                        selection: Binding(
                            get: { item.expirationDate ?? Date() },
                            set: { item.expirationDate = $0 }
                        ),
                        displayedComponents: .date
                    )

                    if item.isExpired {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("期限切れです")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    } else if item.isExpiringSoon {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            Text("まもなく期限切れです（30日以内）")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                }
            }

            Section(header: Text("備考")) {
                TextEditor(text: $item.notes)
                    .frame(height: 100)
            }

            Section(header: Text("チェック状態")) {
                Toggle("チェック済み", isOn: $item.isChecked)

                if let lastChecked = item.lastCheckedDate {
                    HStack {
                        Text("最終チェック日時")
                        Spacer()
                        Text(formattedDateTime(lastChecked))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("物品詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    if item.isChecked && item.lastCheckedDate == nil {
                        item.lastCheckedDate = Date()
                    }
                    onSave()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
