//
//  SettingsView.swift
//  DoctorHeliChecklistApp
//
//  設定画面（Google Sheets 連携設定）
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var sheetsService: GoogleSheetsService

    @State private var spreadsheetId = ""
    @State private var apiKey = ""
    @State private var showingSaveAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Google Sheets 連携設定")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("スプレッドシートID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("例: 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms", text: $spreadsheetId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("API キー")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("Google Cloud Console で取得", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                    }

                    if sheetsService.isConnected {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("連携済み")
                                .foregroundColor(.green)
                        }
                    }
                }

                Section(header: Text("設定方法")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("1. Google Sheets でスプレッドシートを作成")
                            .font(.caption)
                        Text("2. Google Cloud Console で API キーを取得")
                            .font(.caption)
                        Text("3. スプレッドシートの共有設定を「リンクを知っている全員」に変更")
                            .font(.caption)
                        Text("4. スプレッドシートのURLからIDをコピー")
                            .font(.caption)

                        Link("詳しい設定方法を見る", destination: URL(string: "https://developers.google.com/sheets/api/guides/concepts")!)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("スプレッドシート形式")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("以下の列を使用してください：")
                            .font(.caption)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("A列: 物品名")
                            Text("B列: カテゴリ")
                            Text("C列: チェック状態（✓ または true/false）")
                            Text("D列: 使用期限（yyyy/MM/dd）")
                            Text("E列: 数量")
                            Text("F列: 保管場所")
                            Text("G列: 備考")
                            Text("H列: 最終チェック日時（yyyy/MM/dd）")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        sheetsService.configure(spreadsheetId: spreadsheetId, apiKey: apiKey)
                        showingSaveAlert = true
                    }
                    .disabled(spreadsheetId.isEmpty || apiKey.isEmpty)
                }
            }
            .alert("設定を保存しました", isPresented: $showingSaveAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
