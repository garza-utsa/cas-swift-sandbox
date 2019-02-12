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
    let fileProps: [URLResourceKey] = [.nameKey, .pathKey, .isDirectoryKey]

    init(targetPath:String) {
        self.targetPath = targetPath
        self.fm = FileManager.default
        //let enumerator = fileManager.enumerator(atPath: ".")
    }

    func crawl() {
        do {
            let targetURL:URL = URL(fileURLWithPath: targetPath)
            let items:[URL] = try fm.contentsOfDirectory(at: targetURL, includingPropertiesForKeys:fileProps, options: enumOptions)
            if (items.count == 1) {
                evaluateSingle(targetURL:items[0])
            } else {
                for item in items {
                    let fa = try item.resourceValues(forKeys:[.isDirectoryKey])
                    examine(targetURL:item, isDirectory:fa.isDirectory!)
                }
            }
            print("finished!")
        } catch {
            print("Failed to read directory")
        }
    }
    
    func evaluateSingle(targetURL:URL) {
        do {
            let singleItem:URL = targetURL
            let sa = try singleItem.resourceValues(forKeys:[.nameKey, .isDirectoryKey])
            let isDirectory = sa.isDirectory ?? false
            let iName = sa.name!
            if ((!isDirectory) && (iName == "index.html")) {
                //collapse the target URL
                //add the collapsed URL to our CollapsedModel
                collapse(targetURL:targetURL)
            }
        } catch {
            print("Failed to evaluate single item \(targetURL)")
        }
    }
    
    func examine(targetURL:URL, isDirectory:Bool) {
        if (isDirectory) {
            let recursiveCrawler = Crawler(targetPath:targetURL.path)
            recursiveCrawler.crawl()
        } else {
        }
    }
    
    func collapse(targetURL:URL) {
        //given a URL /a/index.html, collapse the content into /a.html, remove the directory /a when complete
        print("collapse! \(targetURL)")
    }
}
