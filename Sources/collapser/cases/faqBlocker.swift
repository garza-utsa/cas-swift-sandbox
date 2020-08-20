//
//  crawler.swift
//  collapser
//
//  Created by John David Garza on 2/11/19.
//

import Foundation
import SwiftSoup

struct FaqBlocker {
    var count:Int = 0
    var targetPath:String = "."
    var definitionPath:String = ""
    var fm:FileManager
    let enumOptions: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsSubdirectoryDescendants, .skipsHiddenFiles]
    let fileProps: [URLResourceKey] = [.nameKey, .pathKey, .isDirectoryKey]
    //let syncQueue:DispatchQueue
    //let semaphore:DispatchSemaphore
    let apiClient:APIClient
    let siteName:String
    
    //print(file)
    //worklaptop: 50 and 13
    //homelaptop: 49 and 13
    //let prefixCount = 46
    //let suffixCount = 13
    
    init(client:APIClient, site:String, targetPath:String, definitionPath:String) {
        //init(client:APIClient, site:String, contentType:String, targetPath:String, dispatchQueue:DispatchQueue, semaphore:DispatchSemaphore) {
        self.apiClient = client
        self.targetPath = targetPath
        self.definitionPath = definitionPath
        self.fm = FileManager.default
        //self.syncQueue = dispatchQueue
        //self.semaphore = semaphore
        self.siteName = site
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
                    var recursiveCrawler = FaqBlocker(client:apiClient, site:siteName, targetPath:item.path, definitionPath:definitionPath)
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
        if (name.hasSuffix(".html")) {
            print("eval: \(name) at \(path)")
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
            //.dropFirst(prefixCount).dropLast(suffixCount)
            var casuri = ""
            var name:String = "test-uri-name"
            var question:String = "This is a test question?"
            var answer:String = "<p>This is a test answer</p>"
            casuri = "_faq/general/campus-events"
            print("casuri will be: \(casuri)")
            print("name will be: \(name)")
            var container:String = try snippet.select("div.accordion").attr("folder")
            if (container != "") {
                casuri = container
            }
            let questions:Elements = try snippet.select(".card")
            print("questions found: \(questions.size())")
            for p in questions {
                question  = try p.select(".card-header h5 span").text()
                if (question.count > 0) {
                    answer = try p.select("div.card-body").html()
                    name = question.lowercased()
                    name = name.replacingOccurrences(of: " ", with: "-")
                    name = name.replacingOccurrences(of: "?", with: "")
                    name = name.replacingOccurrences(of: "'", with: "")
                    name = name.replacingOccurrences(of: "\"", with: "")
                    name = name.replacingOccurrences(of: ",", with: "")
                    name = name.replacingOccurrences(of: "(", with: "")
                    name = name.replacingOccurrences(of: ")", with: "")
                    name = name.replacingOccurrences(of: "/", with: "")
                    name = name.replacingOccurrences(of: "#", with: "")
                    name = name.replacingOccurrences(of: "&", with: "")
                    name = name.replacingOccurrences(of: ";", with: "")
                        //.replacingOcccurences(of: " ", with: "-")
                    print("\t creating asset for profile \(name): \(question)")
                    let assetObj = createBlockRequest(u:apiClient.username, p:apiClient.password, site:siteName, definitionPath: definitionPath,
                                                      parentFolderPath: casuri, name: name, question: question, answer: answer)
                    let encoder = JSONEncoder()
                    let encodedAsset = try encoder.encode(assetObj)
                    // does not wait. But the code in notify() gets run
                    // after enter() and leave() calls are balanced
                    //syncQueue.async {
                    print("will post asset: \(encodedAsset)")
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
            }

        } catch Exception.Error(let type, let message) {
            print("Error while trying to parse snippet from \(file)")
            print("\(type):\(message)")
        } catch {
            print("***ERROR***")
        }
    }
    
    public func createBlockRequest(u:String, p:String, site:String, definitionPath:String, parentFolderPath:String, name:String, question:String, answer:String) ->
        CreateBlockRequest {
            var brequest:CreateBlockRequest
            //let md:Metadata = Metadata(displayName:title, title:title, startDate: nil)
            let auth:Authentication = Authentication(username: u, password: p)
            var sdn:StructuredData = StructuredData(structuredDataNodes: [], definitionPath: nil)
            //let docStr:String = try doc.body()!.html().htmlEscape(allowUnsafeSymbols:true)
            let questionTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "question", text: question, structuredDataNodes: nil, filePath: nil, assetType: nil)
            let answerTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "answer", text: answer, structuredDataNodes: nil, filePath: nil, assetType: nil)
            sdn = StructuredData(structuredDataNodes: [questionTType, answerTType], definitionPath:definitionPath)
            let b:xhtmlDataDefinitionBlock = xhtmlDataDefinitionBlock(
                structuredData:sdn,
                parentFolderPath: parentFolderPath,
                siteName: site,
                name: name)
            let a:BlockAsset = BlockAsset(xhtmlDataDefinitionBlock: b)
            brequest = CreateBlockRequest(authentication: auth, asset: a)
            return brequest
    }
}
