//
//  csver.woft
//  csv parser / block asset creator
//
//  Created by John David Garza on 2/11/19.
//

import Foundation
import SwiftSoup
import CSV

struct CSVer {
    var count:Int = 0
    var targetPath:String = "."
    var definitionPath:String = ""
    var fm:FileManager
    let enumOptions: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsSubdirectoryDescendants, .skipsHiddenFiles]
    let fileProps: [URLResourceKey] = [.nameKey, .pathKey, .isDirectoryKey]
    let apiClient:APIClient
    let siteName:String
    
    init(client:APIClient, site:String, targetPath:String, definitionPath:String) {
        //init(client:APIClient, site:String, contentType:String, targetPath:String, dispatchQueue:DispatchQueue, semaphore:DispatchSemaphore) {
        self.apiClient = client
        self.targetPath = targetPath
        self.definitionPath = definitionPath
        self.fm = FileManager.default
        self.siteName = site
    }
    
    mutating func crawl() -> Int {
        do {
            let targetURL:URL = URL(fileURLWithPath: targetPath)
            let items:[URL] = try fm.contentsOfDirectory(at: targetURL, includingPropertiesForKeys:fileProps, options: enumOptions)
            for item in items {
                let fa = try item.resourceValues(forKeys:[.nameKey, .isDirectoryKey, .pathKey])
                let isDirectory = fa.isDirectory ?? false
                if (isDirectory) {
                    //targetpath should be a single file
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
        if (name == "personnel.csv") {
            //print("parse: \(name) at \(path)")
            print(targetURL.relativePath)
            let stream = InputStream(fileAtPath: targetURL.relativePath)!
            let csv = try! CSVReader(stream: stream, hasHeaderRow: true) // It must be true.
            while let row = csv.next() {
                print("\(row)")
                let blockObj = buildProfile(row:row)
                post(block:blockObj)
            }
        } else {
            print("skipping: \(name) at \(path)")
        }
    }

    func reorderName(fullName:String) -> String {
        let cleanName:String = fullName.replacingOccurrences(of: ".", with: "").lowercased()
        let names:[Substring] = cleanName.split(separator:" ")
        let last = names.last
        let rest:[Substring] = names.dropLast()
        var reordered:String = String(last!)
        for n in rest {
            reordered.append("-")
            reordered.append(String(n))
        }
        return reordered
    }
    
    func buildProfile(row:[String]) -> CreateBlockRequest {
        var casuri = "/about/_staff"
        var name:String = "test-uri-name"
        var sdnTitle:String = "test block title"
        var sdnName:String = "Test Name Goes Here"
        var sdnBuilding:String = "MB 4.120"
        var sdnPhone:String = "(210) 458-4110"
        var sdnEmail:String = "vpaacomms@utsa.edu"
        //0: Full Name
        //1: Title
        //2: Building
        //3: Phone
        //4: Email
        sdnName = "\(row[0])"
        sdnTitle = "\(row[1])"
        if (row[2] != "") {
            sdnBuilding = "\(row[2])"
        }
        if (row[3] != "") {
            sdnPhone = "\(row[3])"
        }
        if (row[4] != "") {
            sdnEmail = "\(row[4])"
        }
        
        var names:String = row[0].trimmingCharacters(in: .whitespacesAndNewlines)
        names = names.replacingOccurrences(of:"Dr. ", with: "")
        names = names.replacingOccurrences(of:"-", with: "")
        let namesArr:[String] = names.split{$0 == " "}.map(String.init)
        let first = namesArr[0]
        let last = namesArr[1]
        name = "\(last)-\(first)"
        
        print("casuri will be: \(casuri) \t\t name will be: \(name)")
        print("\t creating asset for profile \(name): \(sdnName)")
        print("\t\t \(sdnTitle)" )
        //let assetObj = createBlockRequest(u:apiClient.username, p:apiClient.password, site:siteName, definitionPath: definitionPath, parentFolderPath: casuri, name: name, title: title, sdnHeadshotURL: sdnHeadshotURL, sdnName: sdnName, sdnCollegeTitle: sdnCollegeTitle, sdnTitle: sdnTitle, sdnEducation:sdnEducation, sdnStaffProfile: sdnStaffProfile, tags:["2019", fullCollegeName])
        let assetObj = createBlockRequest(u:apiClient.username, p:apiClient.password, site:siteName, definitionPath: definitionPath, parentFolderPath: casuri, name: name, title: sdnName, sdnTitle: sdnTitle, sdnName:sdnName, sdnBuilding:sdnBuilding, sdnPhone:sdnPhone, sdnEmail:sdnEmail)
        return assetObj
    }
    
    public func createBlockRequest(u:String, p:String, site:String, definitionPath:String, parentFolderPath:String, name:String, title:String, sdnTitle:String, sdnName:String, sdnBuilding:String, sdnPhone:String, sdnEmail:String) ->
        CreateBlockRequest {
            var brequest:CreateBlockRequest
            let md:Metadata = Metadata(displayName:title, title:title, startDate: nil)
            let auth:Authentication = Authentication(username: u, password: p)
            var sdn:StructuredData = StructuredData(structuredDataNodes: [], definitionPath: nil)
            //let docStr:String = try doc.body()!.html().htmlEscape(allowUnsafeSymbols:true)
            let titleTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "fullName", text: sdnName, structuredDataNodes: nil, filePath: nil, assetType: nil)
            let fullNameTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "title", text: sdnTitle, structuredDataNodes: nil, filePath: nil, assetType: nil)
            let buildTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "campusAddress1", text: sdnBuilding, structuredDataNodes: nil, filePath: nil, assetType: nil)
            let phoneTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "phone", text: sdnPhone, structuredDataNodes: nil, filePath: nil, assetType: nil)
            let emailTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "email", text: sdnEmail, structuredDataNodes: nil, filePath: nil, assetType: nil)
            let smGroup:StructuredDataNode = StructuredDataNode(type: "group", identifier: "staffMember", text: nil, structuredDataNodes: [fullNameTType, titleTType, buildTType, phoneTType, emailTType], filePath: nil, assetType: nil)
            sdn = StructuredData(structuredDataNodes: [smGroup], definitionPath:definitionPath)
            let casTags:[CascadeTag] = []
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
    
    func post(block:CreateBlockRequest) {
        do {
            let path = block.asset.xhtmlDataDefinitionBlock.parentFolderPath
            let name = block.asset.xhtmlDataDefinitionBlock.name
            let encoder = JSONEncoder()
            let encodedAsset = try encoder.encode(block)
            print(String(decoding: encodedAsset, as: UTF8.self))

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
            //}
        } catch {
            print("***ERROR***")
        }
    }
}
