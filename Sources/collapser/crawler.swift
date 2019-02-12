//
//  crawler.swift
//  collapser
//
//  Created by John David Garza on 2/11/19.
//

import Foundation

struct Crawler {
    var count:Int = 0
    var targetPath:String = "."
    var fm:FileManager
    let enumOptions: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsSubdirectoryDescendants, .skipsHiddenFiles]

    init(targetPath:String) {
        self.targetPath = targetPath
        self.fm = FileManager.default
        //let enumerator = fileManager.enumerator(atPath: ".")
    }

    func crawl() {
        do {
            let targetURL:URL = URL(fileURLWithPath: targetPath)
            let items:[URL] = try fm.contentsOfDirectory(at: targetURL, includingPropertiesForKeys:[.nameKey, .pathKey, .isDirectoryKey], options: enumOptions)
            print("Found \(items.count) items:")
            if (items.count == 1) {
                print("consider collapsing this item")
                print("item: \(items[0])")
            } else {
                for item in items {
                    let fileAttributes = try item.resourceValues(forKeys:[.isDirectoryKey])
                    examine(targetURL:item, isDirectory:fileAttributes.isDirectory!)
                }
            }
        } catch {
            print("Failed to read directory")
        }
    }
    
    func examine(targetURL:URL, isDirectory:Bool) {
        print("Found \(targetURL)")
        if (isDirectory) {
            print(targetURL.path);
            let recursiveCrawler = Crawler(targetPath:targetURL.path)
            print("it's a directory!")
            recursiveCrawler.crawl()
        } else {
            print("it's not a directory!")
        }
    }
}
