//
//  ViewController.swift
//  Localised Strings
//
//  Created by Timothy Barnard on 09/03/2018.
//  Copyright © 2018 Timothy Barnard. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var tableView: NSTableView!
    
    var translations = [[String]]()
    var currentProjectPath: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    
    private func readDataFromCSV(fileName:String, fileType: String)-> String? {
        guard let filepath = NSURL(fileURLWithPath: fileName).path else { return nil }
        do {
            return try String(contentsOfFile: filepath, encoding: .utf8)
        } catch {
            print("File Read Error for file \(filepath)")
            return nil
        }
    }
    
    private func removeAllTableColumn() {
        let tColCount = self.tableView.tableColumns.count
        for value in 0..<tColCount {
            let column = self.tableView.tableColumns[value]
            self.tableView.removeTableColumn(column)
        }
    }
    
    private func setupTableView() {
        self.removeAllTableColumn()
        let firstRow = translations[0]
        let W = CGFloat (50)
        for (index, value) in firstRow.enumerated() {
            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "\(index)"))
            col.minWidth = W
            col.title = value
            tableView.addTableColumn(col)
        }
        self.tableView.reloadData()
    }
    
    private func csv(data: String) -> [[String]] {
        var result: [[String]] = []
        let rows = data.components(separatedBy: "\n")
        for row in rows {
            let columns = row.components(separatedBy: ",")
            result.append(columns)
        }
        return result
    }
    
    private func extractAllFile(atPath path: String, withExtension fileExtension: String, fileName: String? = nil) -> [String] {
        let pathURL = NSURL(fileURLWithPath: path, isDirectory: true)
        var allFiles: [String] = []
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(atPath: path) {
            for file in enumerator {
                if let fileString = file as? String {
                    let urlPath = NSURL(fileURLWithPath: fileString, relativeTo: pathURL as URL)
                    if let path = urlPath.path, path.hasSuffix(".\(fileExtension)"){
                        if let name = fileName {
                            if let urlFileName = urlPath.lastPathComponent, urlFileName == "\(name).\(fileExtension)" {
                                allFiles.append(path)
                            }
                        } else {
                            allFiles.append(path)
                        }
                    }
                }
            }
        }
        return allFiles
    }
    
    private func writeToFile(_ contents: String ) {
        let mySave = NSSavePanel()
        mySave.canCreateDirectories = true
        mySave.allowedFileTypes = []
        mySave.begin { (result) in
            
            if result == NSApplication.ModalResponse.OK {
                let filename = mySave.url
                
                do {
                    try contents.write(to: filename!, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    // failed to write file (bad permissions, bad filename etc.)
                }
            }
        }
    }
    
    private func createStringsFile(_ values: [String], keys: [String]) -> String {
        var contents: String = ""
        
        for (index, key) in keys.enumerated() {
            if index <= values.count {
                let value = values[index]
                contents += "\"\(key)\" = \"\(value)\";"
            }
        }
        return contents
    }
    
    @IBAction func openProject(_ sender: NSButton) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a project";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                self.currentProjectPath = result!
                let files = self.extractAllFile(atPath: path, withExtension: "strings", fileName: "Localizable")
                let fileString = files.joined(separator: "\n")
                textView.string = fileString
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    @IBAction func readCSV(_ sender: NSButton) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a csv file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                if let contents = self.readDataFromCSV(fileName: path, fileType: ".csv") {
                    let values = self.csv(data: contents)
                    self.translations = values
                    self.setupTableView()
                }
                
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    @IBAction func exportStrings(_ sender: NSButton) {
        let keys = self.translations[0]
        let translation = self.translations[3]
        let contents = self.createStringsFile(translation, keys: keys)
        self.writeToFile(contents)
    }
}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return translations.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let stringValue = tableColumn?.identifier.rawValue, let col = Int(stringValue) {
            if row <= translations.count-1 {
                if col <= translations[row].count-1 {
                    return self.translations[row][col]
                }
            }
        }
        return nil
    }
}
