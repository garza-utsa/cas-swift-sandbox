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
    let syncQueue:DispatchQueue
    let semaphore:DispatchSemaphore
    let apiClient:APIClient
    let siteName:String
    let targetContentType:String

    init(client:APIClient, site:String, contentType:String, targetPath:String, dispatchQueue:DispatchQueue, semaphore:DispatchSemaphore) {
        self.apiClient = client
        self.targetPath = targetPath
        self.fm = FileManager.default
        self.syncQueue = dispatchQueue
        self.semaphore = semaphore
        self.siteName = site
        self.targetContentType = contentType
        //let enumerator = fileManager.enumerator(atPath: ".")
    }
    
    mutating func crawl() -> Int {
        do {
            let targetURL:URL = URL(fileURLWithPath: targetPath)
            let items:[URL] = try fm.contentsOfDirectory(at: targetURL, includingPropertiesForKeys:fileProps, options: enumOptions)
            for item in items {
                let fa = try item.resourceValues(forKeys:[.nameKey, .isDirectoryKey, .pathKey])
                let isDirectory = fa.isDirectory ?? false
                if (isDirectory) {
                    //recurse!
                    var recursiveCrawler = Poster(client:apiClient, site:siteName, contentType:targetContentType,targetPath:item.path, dispatchQueue:syncQueue, semaphore:semaphore)
                    self.count = count + recursiveCrawler.crawl()
                } else {
                    evaluate(targetURL:item, targetResources:fa)
                }
                self.count = count + 1
            }
        } catch {
            print("Failed to read directory")
        }
        return count
    }
    
    mutating func evaluate(targetURL:URL, targetResources:URLResourceValues) {
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
            let prefixCount = 50
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
            let assetObj = createAssetRequest(u:apiClient.username, p:apiClient.password, site:siteName, contentType:targetContentType, title: title, parentFolderPath: casuri, name: name, doc: snippet)
            let encoder = JSONEncoder()
            let encodedAsset = try encoder.encode(assetObj)
            // does not wait. But the code in notify() gets run
            // after enter() and leave() calls are balanced
            syncQueue.async {
                self.apiClient.post(PostAsset(), payload:encodedAsset, path:path, name:name) { response in
                    switch response {
                    case .success(let response):
                        print("created: \(response.createdAssetId!)")
                    case .failure(let error):
                        print("****POST FAILED****")
                        print(error)
                    }
                }
            }
            let st = semaphore.wait(timeout: .now() + 0.15)
            print(st)            
        } catch Exception.Error(let type, let message) {
            print("Error while trying to parse snippet from \(file)")
            print("\(type):\(message)")
        } catch {
            print("***ERROR***")
        }
    }
}
