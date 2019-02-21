//
//  sanitizer.swift
//  collapser
//
//  Created by John David Garza on 2/11/19.
//

import Foundation
import SwiftSoup

struct Sanitizer {
    var count:Int = 0
    var targetPath:String = "."
    var fm:FileManager
    let enumOptions: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsSubdirectoryDescendants, .skipsHiddenFiles]
    let fileProps: [URLResourceKey] = [.nameKey, .pathKey, .isDirectoryKey]
    let siteName:String

    init(targetPath:String, siteName:String) {
        self.targetPath = targetPath
        self.fm = FileManager.default
        self.siteName = siteName
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
                    let recursiveCrawler = Sanitizer(targetPath:item.path, siteName:siteName)
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
        do {
            let path = targetResources.path ?? ""
            let name = targetResources.name ?? ""
            if (name == "snippet.html") {
                //print("parse: \(name) at \(path)")
                var snippet:Document = parseTarget(file:targetURL)
                if (snippet.body() != nil) {
                    snippet = cleanRefs(file:targetURL, snippet:snippet, path:path)
                    var contentStr:String = ""
                    contentStr = try contentStr + snippet.body()!.html()
                    print("contentStr: \(contentStr)")
                    updateSnip(file:targetURL, snippet:contentStr)
                } else {
                    print("content-main div not found in \(name) for \(path)")
                }
            } else {
                //print("skipping: \(name) at \(path)")
            }
        } catch Exception.Error(let type, let message) {
            print("Error while trying to overwrite html from \(targetURL)")
            print("\(type):\(message)")
        } catch {
            print("***ERROR***")
        }
    }
    
    func updateSnip(file:URL, snippet:String) {
        do {
            let fileData:Data = snippet.data(using: .utf8)!
            try fileData.write(to: file, options: [.atomic])
        } catch Exception.Error(let type, let message) {
            print("Error while trying to overwrite html from \(file)")
            print("\(type):\(message)")
        } catch {
            print("***ERROR***")
        }
    }
    
    func parseTarget(file:URL) -> Document {
        var doc:Document = Document("")
        do {
            let html:String = try String(contentsOf:file, encoding: .utf8)
            doc = try SwiftSoup.parse(html)
        } catch Exception.Error(let type, let message) {
            print("Error while trying to parse html from \(file)")
            print("\(type):\(message)")
        } catch {
            print("***ERROR***")
        }
        return doc
    }
    
    func cleanRefs(file:URL, snippet:Document, path:String) -> Document {
        do {
            //print(file)
            //worklaptop: 50 and 13
            //homelaptop: 49 and 13
            let prefixCount = 50
            let suffixCount = 13
            var casuri:String = file.path.dropFirst(prefixCount).dropLast(suffixCount).lowercased()
            if (casuri == "") {
                casuri = "/"
            }
            
            let anchors:Elements = try snippet.select("a")
            let images:Elements = try snippet.select("img")
            print("casuri: \(casuri)")
            print("start URL: \(file)")
            print("")
            for anchor in anchors {
                var href = try anchor.attr("href")
                let hrefExt = URL(fileURLWithPath: href).pathExtension
                //print("href ext: \(hrefExt)")
                var fileref = file
                fileref.deleteLastPathComponent()
                print("evaluate href: \(href)")
                if (hrefExt == "pdf") || (hrefExt.hasPrefix("html")) {
                    if (!href.hasPrefix("http")) {
                        //print("unsanitized href: \(href)")
                        while (href.hasPrefix("../")) {
                            fileref.deleteLastPathComponent()
                            href = String(href.dropFirst(3))
                            //fileref.appendPathComponent(href)
                        }
                        //href = "site://" + siteName + "/" + href
                        fileref = fileref.appendingPathComponent(href)
                        var lastComponent = fileref.lastPathComponent
                        if (lastComponent.hasPrefix("index.html")) {
                            lastComponent = "index" + String(lastComponent.dropFirst(10))
                        }
                        //print("extension: \(fileref.pathExtension)")
                        fileref.deleteLastPathComponent()
                        fileref = fileref.appendingPathComponent(lastComponent)
                        let newurl:String = "site://" + siteName + fileref.path.dropFirst(50)
                        print("sanitized url: \(newurl)")
                        print("last component: \(lastComponent)")
                        try anchor.attr("href", newurl)
                        print("")
                        print("")
                    }
                }
            }
            
            for image in images {
                var src = try image.attr("src")
                let srcExt = URL(fileURLWithPath: src).pathExtension
                print("src ext: \(srcExt)")
                var fileref = file
                fileref.deleteLastPathComponent()
                print("evaluate href: \(src)")
                if (!src.hasPrefix("http")) {
                    //print("unsanitized href: \(href)")
                    while (src.hasPrefix("../")) {
                        fileref.deleteLastPathComponent()
                        src = String(src.dropFirst(3))
                        //fileref.appendPathComponent(href)
                    }
                    //href = "site://" + siteName + "/" + href
                    fileref = fileref.appendingPathComponent(src)
                    let lastComponent = fileref.lastPathComponent
                    //print("extension: \(fileref.pathExtension)")
                    fileref.deleteLastPathComponent()
                    fileref = fileref.appendingPathComponent(lastComponent)
                    let newurl:String = "site://" + siteName + fileref.path.dropFirst(50)
                    print("sanitized url: \(newurl)")
                    print("")
                    print("")
                    try image.attr("src", newurl)
                }
            }
        } catch Exception.Error(let type, let message) {
            print("Error while trying to parse snippet from \(file)")
            print("\(type):\(message)")
        } catch {
            print("***ERROR***")
        }
        return snippet
    }
}
