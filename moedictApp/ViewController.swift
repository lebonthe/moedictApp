//
//  ViewController.swift
//  moedictApp
//
//  Created by Min Hu on 2023/12/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textField: UITextField! // 文字輸入欄位
    @IBOutlet weak var relatedButton: UIButton! // 相關詞彙的按鈕
    @IBOutlet weak var tableView: UITableView! // 顯示資料的表格視圖
    var wordDefinition: WordDefinition? // 查詢的字詞定義
    var heteronyms = [Heteronym]() // 存放不同發音的字詞
    

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension // 設定表格列的高度自動調整
        tableView.estimatedRowHeight = 100 // 預估的行高
        relatedButton.showsMenuAsPrimaryAction = true // 讓按鈕顯示菜單
        // 收鍵盤
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)) // 點擊手勢用來隱藏鍵盤
        tapGesture.cancelsTouchesInView = false // 不取消視圖中的觸摸事件
        view.addGestureRecognizer(tapGesture) // 將手勢加入到視圖中
    }
    // 點擊搜索按鈕的事件處理
    @IBAction func searchButtonClick(_ sender: UIButton) {
        // 使用 guard 來檢查 textField 中是否有文字，並且該文字不是空的
        guard let text = textField.text, !text.isEmpty else { return }
        // 若檢查通過（即文本欄中有非空的文字），則進行下一步
        // 若檢查不通過（即文本欄是空的或沒有文字），則直接返回，不執行下面的代碼

        fetchDefs(word: text) // 呼叫 fetchDefs 函數，並將 textField 中的文字作為參數傳入
    }

    // 從網路抓取指定詞彙的定義
    func fetchDefs(word: String) {
        let urlStr = "https://www.moedict.tw/uni/\(word)" // 將要查詢的詞彙加入網址中
        if let url = URL(string: urlStr) { // 檢查網址是否有效並創建 URL 物件
            // 使用 URLSession 來發起一個網路請求
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data { // 檢查返回的資料是否存在
                    let decoder = JSONDecoder() // 創建一個 JSON 解碼器
                    do {
                        let wordDefinition = try decoder.decode(WordDefinition.self, from: data) // 嘗試解碼返回的資料到 WordDefinition 結構體
                        self.wordDefinition = wordDefinition // 將解碼後的資料存儲到 wordDefinition 變數中
                        self.heteronyms = wordDefinition.heteronyms // 將解碼後的資料中的 heteronyms 屬性更新到 heteronyms 變數中
                        DispatchQueue.main.async { // 在主執行緒中更新 UI
                            self.tableView.reloadData() // 重新載入 tableView 的資料
                            self.fetchRelatedWords(word: word) // 呼叫 fetchRelatedWords 方法來抓取與詞彙相關的其他詞彙
                        }
                    } catch { // 捕捉並處理解碼過程中可能發生的錯誤
                        print(error) // 輸出錯誤訊息
                    }
                }
            }.resume() // 啟動這個網路請求任務
        }
    }

    // 從網路上抓取與指定字詞相關的詞彙
    func fetchRelatedWords(word: String) {
        
        let urlStr = "https://raw.githubusercontent.com/g0v/moedict-webkit/master/a/index.json" // 設定抓取資料的網址
        guard let url = URL(string: urlStr) else { return } // 檢查網址是否有效，若無效則直接返回

        URLSession.shared.dataTask(with: url) { data, response, error in
            // 使用共享的 URLSession 進行網路請求
            guard let data = data, error == nil else { return } // 確保請求沒有錯誤且有資料返回，否則返回

            do {
                let allWords = try JSONDecoder().decode([String].self, from: data) // 嘗試解碼獲取到的資料
                let relatedWords = allWords.filter { $0.contains(word) } // 從所有詞彙中篩選出包含指定字詞的詞彙
                // 在主執行緒中更新 UI
                DispatchQueue.main.async {
                  // 為每個相關詞彙創建一個 Menu 項目
                  self.relatedButton.menu = UIMenu(children: relatedWords.map { relatedWord in
                  // 設定當選項被選中時的行為
                  UIAction(title: relatedWord, handler: { _ in
                  // 將文本欄位的內容設定為選中的詞彙
                  self.textField.text = relatedWord
                       })
                     })
                   }
            } catch {
                print("error") // 如果解碼過程中出現錯誤，則輸出錯誤訊息
            }
        }.resume() // 啟動網路任務
    }

    
    @objc func hideKeyboard() {
        // 隱藏鍵盤的方法
        view.endEditing(true) // 結束編輯狀態
    }
    
}

// 擴展 ViewController 以符合 UITableViewDataSource 協定
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    // 決定 section 的數量，根據 heteronyms 陣列的長度決定
    func numberOfSections(in tableView: UITableView) -> Int {
        heteronyms.count
    }
    
    // 每個 section 的標題
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let wordTitle = wordDefinition?.title {
            let bopomofo = heteronyms[section].bopomofo
            return "\(wordTitle) - \(bopomofo)"
        }
        return nil
    }
    
    // 每個 section 中 row 的數量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        heteronyms[section].definitions.count
    }
    
    // 設定每個 cell 的內容
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 使用 TableViewCell，如果找不到則報錯
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TableViewCell.self)", for: indexPath) as? TableViewCell else { fatalError("dequeueReusableCell TableViewCell failed")}
        
        let heteronym = heteronyms[indexPath.section] // 獲取當前發音
        let definition = heteronym.definitions[indexPath.row] // 獲取當前定義
        let typeAndDef = "\(definition.type ?? "詞")： \(definition.def)" // 組合類型和定義
        
        let examples = definition.example?.joined(separator: "") // 組合例句
        let links = definition.link?.joined(separator: "") // 組合相關連結
        var text = "\(typeAndDef)\n\(examples ?? "")\n"
        if let links {
            text.append("\(links)\n")
        }
        cell.textLabel?.text = text // 設定 cell 文字
        cell.textLabel?.numberOfLines = 0 // 允許多行顯示
        tableView.separatorStyle = .none // 不顯示分隔線
        
        return cell
    }
}
 

