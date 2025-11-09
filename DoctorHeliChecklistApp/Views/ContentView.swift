//
//  ContentView.swift
//  DoctorHeliChecklistApp
//
//  メインのチェックリスト画面
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChecklistViewModel()
    @State private var showingSettings = false
    @State private var showingAddItem = false
    @State private var searchText = ""
    @State private var selectedCategory: String = "すべて"

    var body: some View {
        NavigationView {
            VStack {
                // 同期ステータス
                if let lastSync = viewModel.sheetsService.lastSyncDate {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("最終同期: \(formattedDate(lastSync))")
                            .font(.caption)
                        Spacer()
                        Button(action: {
                            viewModel.syncWithSheets()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                }

                // カテゴリフィルター
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        CategoryFilterButton(title: "すべて", isSelected: selectedCategory == "すべて") {
                            selectedCategory = "すべて"
                        }
                        ForEach(["医薬品", "医療機器", "消耗品", "緊急用品", "その他"], id: \.self) { category in
                            CategoryFilterButton(title: category, isSelected: selectedCategory == category) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                // チェックリスト
                List {
                    ForEach(filteredItems) { item in
                        NavigationLink(destination: ItemDetailView(item: binding(for: item), onSave: {
                            viewModel.updateItem(item)
                        })) {
                            SupplyItemRow(item: item) {
                                viewModel.toggleCheck(item)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "物品を検索")
            }
            .navigationTitle("ドクターヘリ物品チェック")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(sheetsService: viewModel.sheetsService)
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView(onAdd: { newItem in
                    viewModel.addItem(newItem)
                })
            }
            .onAppear {
                viewModel.loadItems()
            }
        }
    }

    private var filteredItems: [SupplyItem] {
        viewModel.items.filter { item in
            let matchesCategory = selectedCategory == "すべて" || item.category == selectedCategory
            let matchesSearch = searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    private func binding(for item: SupplyItem) -> Binding<SupplyItem> {
        guard let index = viewModel.items.firstIndex(where: { $0.id == item.id }) else {
            fatalError("Item not found")
        }
        return $viewModel.items[index]
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct SupplyItemRow: View {
    let item: SupplyItem
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isChecked ? .green : .gray)
                    .imageScale(.large)
            }
            .buttonStyle(BorderlessButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)

                HStack {
                    Text(item.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)

                    if let expirationDate = item.expirationDate {
                        HStack(spacing: 2) {
                            Image(systemName: item.isExpired ? "exclamationmark.triangle.fill" : item.isExpiringSoon ? "clock.fill" : "calendar")
                                .foregroundColor(item.isExpired ? .red : item.isExpiringSoon ? .orange : .gray)
                            Text(formattedDate(expirationDate))
                                .font(.caption)
                                .foregroundColor(item.isExpired ? .red : item.isExpiringSoon ? .orange : .secondary)
                        }
                    }
                }
            }

            Spacer()

            Text("\(item.quantity)")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}
