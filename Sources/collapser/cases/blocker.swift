//
//  crawler.swift
//  collapser
//
//  Created by John David Garza on 2/11/19.
//

import Foundation
import SwiftSoup

struct Blocker {
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
    let prefixCount = 46
    let suffixCount = 13
    
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
                    var recursiveCrawler = Blocker(client:apiClient, site:siteName, targetPath:item.path, definitionPath:definitionPath)
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
        if (name == "new-faculty-2018.html") {
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
    
    func reorderName(fullName:String) -> String {
        let cleanName:String = fullName.replacingOccurrences(of: ".", with: "").lowercased()
        let names:[Substring] = cleanName.split(separator:" ")
        let last = names.last
        var rest:[Substring] = names.dropLast()
        var reordered:String = String(last!)
        for n in rest {
            reordered.append("-")
            reordered.append(String(n))
        }
        return reordered
    }
    
    func post(file:URL, snippet:Document, path:String) {
        do {
            //.dropFirst(prefixCount).dropLast(suffixCount)
            var casuri = ""
            var name:String = "test-uri-name"
            var title:String = "test block title"
            var sdnHeadshotURL = "img/2018/abu-lail.jpg"
            var sdnName:String = "Test Name Goes Here"
            var sdnCollegeTitle:String = "School of Name-ish"
            var sdnTitle:String = "Professor-ish"
            var sdnEmail:String = "name@utsa.edu"
            var sdnEducation:String = "Ph.D. School of Name-ish"
            var sdnStaffProfile:String = "Flank ham hock landjaeger chuck. Ball tip turkey ribeye ham hock tri-tip leberkas short ribs spare ribs drumstick biltong pancetta. Hamburger jowl turkey, ham hock sausage biltong tri-tip filet mignon. Chuck beef ribs pork chop prosciutto leberkas capicola. Tail frankfurter pork, boudin drumstick shank sausage. Shankle boudin pork belly cow buffalo meatloaf."
            casuri = "_cascade/blocks/2019-faculty"
            print("casuri will be: \(casuri)")
            print("name will be: \(name)")

            let profiles:Elements = try snippet.select("td")
            print("profiles found: \(profiles.size())")
            for p in profiles {
                title  = try p.select("h3").text()
                sdnTitle = ""
                sdnEducation = ""
                sdnCollegeTitle = ""
                if (title.count > 0) {
                    var titles = try p.select("div")
                    sdnTitle = try titles.get(0).text()
                    let titlesSize = titles.size()
                    sdnEducation = try titles.get(titlesSize - 1).text()
                    var els = titles.dropFirst(1)
                    var last = els.dropLast(1)
                    for t in last {
                        try sdnCollegeTitle.append(t.text())
                        sdnCollegeTitle.append(" ")
                    }
                    sdnHeadshotURL = try p.select("img").attr("src").replacingOccurrences(of: "images/faculty18", with: "img/2018")
                    sdnStaffProfile = try p.select("p").text()
                    name = reorderName(fullName: title.lowercased())
                    //name = title.lowercased().replacingOccurrences(of: ".", with: "").replacingOccurrences(of: " ", with: "-")
                    print("\t creating asset for profile \(name): \(title) count: \(sdnStaffProfile.count) \t \(sdnHeadshotURL)")
                    print("\t\t \(sdnTitle)" )
                    print("\t\t \(sdnEducation) ")
                    print("\t\t \(sdnCollegeTitle)")
                    let assetObj = createBlockRequest(u:apiClient.username, p:apiClient.password, site:siteName, definitionPath: definitionPath, parentFolderPath: casuri, name: name, title: title,
                                                      sdnHeadshotURL: sdnHeadshotURL, sdnName: sdnName, sdnCollegeTitle: sdnCollegeTitle, sdnTitle: sdnTitle,
                                                    sdnEducation:sdnEducation, sdnStaffProfile: sdnStaffProfile, tags:["2019", sdnCollegeTitle])
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
            
            /*
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
            */
        } catch Exception.Error(let type, let message) {
            print("Error while trying to parse snippet from \(file)")
            print("\(type):\(message)")
        } catch {
            print("***ERROR***")
        }
    }
    
    public func createBlockRequest(u:String, p:String, site:String, definitionPath:String, parentFolderPath:String, name:String, title:String, sdnHeadshotURL:String, sdnName:String, sdnCollegeTitle:String, sdnTitle:String, sdnEducation:String, sdnStaffProfile:String, tags:[String]) ->
        CreateBlockRequest {
            var brequest:CreateBlockRequest
            let md:Metadata = Metadata(displayName:title, title:title)
                //, startDate: nil)
            let auth:Authentication = Authentication(username: u, password: p)
            var sdn:StructuredData = StructuredData(structuredDataNodes: [], definitionPath: nil)
            //let docStr:String = try doc.body()!.html().htmlEscape(allowUnsafeSymbols:true)
            let headshotFType:StructuredDataNode = StructuredDataNode(type: "asset", identifier: "headshot", text: nil, structuredDataNodes: nil, filePath:sdnHeadshotURL, assetType:"file")
            let profileTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "staffProfile", text: sdnStaffProfile, structuredDataNodes: nil, filePath: nil, assetType: nil)
            let educationTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "education", text: sdnEducation, structuredDataNodes: nil, filePath: nil, assetType: nil)
            let titleTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "title", text: sdnTitle, structuredDataNodes: nil, filePath: nil, assetType: nil)
            let collegeTitleTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "college-title", text: sdnCollegeTitle, structuredDataNodes: nil, filePath: nil, assetType: nil)
            let smGroup:StructuredDataNode = StructuredDataNode(type: "group", identifier: "staffMember", text: nil, structuredDataNodes: [headshotFType, collegeTitleTType, titleTType, educationTType, profileTType], filePath: nil, assetType: nil)
            sdn = StructuredData(structuredDataNodes: [smGroup], definitionPath:definitionPath)
            var casTags:[CascadeTag] = []
            for tag in tags {
                casTags.append(CascadeTag(name: tag))
            }
            
            let b:xhtmlDataDefinitionBlock = xhtmlDataDefinitionBlock(
                structuredData:sdn,
                metadata: md,
                parentFolderPath: parentFolderPath,
                siteName: site,
                name: name,
                tags:casTags)
            let a:BlockAsset = BlockAsset(xhtmlDataDefinitionBlock: b)
            brequest = CreateBlockRequest(authentication: auth, asset: a)
            return brequest
    }
}
