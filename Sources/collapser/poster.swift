//
//  crawler.swift
//  collapser
//
//  Created by John David Garza on 2/11/19.
//

import Foundation
import SwiftSoup

struct Poster {
    var count:Int = 0
    var targetPath:String = "."
    var fm:FileManager
    let enumOptions: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsSubdirectoryDescendants, .skipsHiddenFiles]
    let fileProps: [URLResourceKey] = [.nameKey, .pathKey, .isDirectoryKey]
    let apiClient = APIClient(username: "jgarza", password: "We can make it Saturday forever!") //real secure
    let syncQueue:DispatchQueue
    let semaphore:DispatchSemaphore
        
    init(targetPath:String, dispatchQueue:DispatchQueue, semaphore:DispatchSemaphore) {
        self.targetPath = targetPath
        self.fm = FileManager.default
        self.syncQueue = dispatchQueue
        self.semaphore = semaphore
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
                    let recursiveCrawler = Poster(targetPath:item.path, dispatchQueue:syncQueue, semaphore:semaphore)
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
        if (name == "snippet.html") {
            //print("parse: \(name) at \(path)")
            let snippet:Document = parseTarget(file:targetURL)
            if (snippet.body() != nil) {
                post(file:targetURL, snippet:snippet, path:path)
            } else {
                print("content-main div not found in \(name) for \(path)")
            }
        } else {
            //print("skipping: \(name) at \(path)")
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
    
    func post(file:URL, snippet:Document, path:String) {
        do {
            //print(file)
            //worklaptop: 50 and 13
            //homelaptop: 49 and 13
            let prefixCount = 49
            let suffixCount = 13
            var casuri:String = file.path.dropFirst(prefixCount).dropLast(suffixCount).lowercased()
            if (casuri == "") {
                casuri = "/"
            }
            let name:String = "index"
            //print("casuri will be: \(casuri)")
            //print("name will be: \(name)")
            let mainDiv:Element = try snippet.getElementsByTag("div").first() ?? Element.init(Tag.init("div"), "")
            let title = try mainDiv.attr("title")
            //print("title: \(title)")
            if (title != "") {
                //print("file content: \(file)")
            }
            let assetObj = createAssetRequest(title: title, parentFolderPath: casuri, name: name, doc: snippet)
            let encoder = JSONEncoder()
            let encodedAsset = try encoder.encode(assetObj)
            // does not wait. But the code in notify() gets run
            // after enter() and leave() calls are balanced
            syncQueue.async {
                self.apiClient.post(PostAsset(), payload:encodedAsset, path:path, name:name) { response in
                    switch response {
                    case .success:
                        print("success")
                    case .failure(let error):
                        print("****POST FAILED****")
                        print(error)
                    }
                }
            }
            semaphore.wait(timeout: .now() + 0.15)
            
        } catch Exception.Error(let type, let message) {
            print("Error while trying to parse snippet from \(file)")
            print("\(type):\(message)")
        } catch {
            print("***ERROR***")
        }
    }
}
