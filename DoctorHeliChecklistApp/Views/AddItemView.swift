//
//  AddItemView.swift
//  DoctorHeliChecklistApp
//
//  新規物品追加画面
//

import SwiftUI

struct AddItemView: View {
    @Environment(\.presentationMode) var presentationMode
    let onAdd: (SupplyItem) -> Void

    @State private var name = ""
    @State private var category = "医薬品"
    @State private var quantity = 1
    @State private var location = ""
    @State private var notes = ""
    @State private var hasExpirationDate = false
    @State private var expirationDate = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("物品名", text: $name)

                    Picker("カテゴリ", selection: $category) {
                        ForEach(["医薬品", "医療機器", "消耗品", "緊急用品", "その他"], id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    Stepper("数量: \(quantity)", value: $quantity, in: 1...9999)

                    TextField("保管場所", text: $location)
                }

                Section(header: Text("使用期限")) {
                    Toggle("使用期限を設定", isOn: $hasExpirationDate)

                    if hasExpirationDate {
                        DatePicker("使用期限", selection: $expirationDate, displayedComponents: .date)
                    }
                }

                Section(header: Text("備考")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("物品を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        let newItem = SupplyItem(
                            name: name,
                            category: category,
                            expirationDate: hasExpirationDate ? expirationDate : nil,
                            quantity: quantity,
                            location: location,
                            notes: notes
                        )
                        onAdd(newItem)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
