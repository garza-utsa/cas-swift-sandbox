//
//  crawler.swift
//  collapser
//
//  Created by John David Garza on 2/11/19.
//

import Foundation
import SwiftSoup

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
            for item in items {
                let fa = try item.resourceValues(forKeys:[.nameKey, .isDirectoryKey, .pathKey])
                let isDirectory = fa.isDirectory ?? false
                if (isDirectory) {
                    //recurse!
                    let recursiveCrawler = Crawler(targetPath:item.path)
                    recursiveCrawler.crawl()
                } else {
                    evaluate(targetURL:item, targetResources:fa)
                }
            }
        } catch {
            print("Failed to read directory")
        }
    }
    
    func evaluate(targetURL:URL, targetResources:URLResourceValues) {
        let path = targetResources.path ?? ""
        let name = targetResources.name ?? ""
        if (name == "index.html") {
            print("parse: \(name) at \(path)")
            let snippet:String = parseTarget(file:targetURL)
            if (snippet != "") {
                snip(file:targetURL, snippet:snippet)
            } else {
                print("content-main div not found in \(name)")
            }
        } else {
            print("skipping: \(name) at \(path)")
        }
    }
    
    func collapse(targetURL:URL) {
        //given a URL /a/index.html, collapse the content into /a.html, remove the directory /a when complete
        print("collapse! \(targetURL)")
    }
    
    func parseTarget(file:URL) -> String {
        var snippet:String = ""
        do {
            let html:String = try String(contentsOf:file, encoding: .utf8)
            let doc:Document = try SwiftSoup.parse(html)
            var title: String = ""
            let headingElement:Element? = try doc.getElementsByTag("h1").last()
            if (headingElement != nil) {
                title = try headingElement!.text()
            }
            var parentDiv: Element = Element.init(Tag.init("div"), "")
            let contentDivs:Elements = try doc.getElementsByClass("content_col_wrapper")
            if (contentDivs.size() == 1) {
                parentDiv = contentDivs.first()!
                try parentDiv.attr("title", title)
                try parentDiv.select("h1").remove()
            }
            snippet = try parentDiv.outerHtml()
        } catch Exception.Error(let type, let message) {
            print("Error while trying to parse html from \(file)")
            print("\(type):\(message)")
        } catch {
            print("***ERROR***")
        }
        return snippet
    }
    
    func snip(file:URL, snippet:String) {
        var newTarget = file.deletingLastPathComponent()
        newTarget = newTarget.appendingPathComponent("snippet.html")
        print("snippet URL is: \(newTarget)")
        do {
            let fileData:Data = snippet.data(using: .utf8)!
            try fileData.write(to: newTarget, options: [.atomic])
        } catch Exception.Error(let type, let message) {
            print("Error while trying to overwrite html from \(file)")
            print("\(type):\(message)")
        } catch {
            print("***ERROR***")
        }
    }
}
