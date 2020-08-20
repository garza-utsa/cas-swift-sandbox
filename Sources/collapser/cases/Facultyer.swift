//
//  csver.woft
//  csv parser / block asset creator
//
//  Created by John David Garza on 2/11/19.
//

import Foundation
import SwiftSoup
import CSV

struct Facultyer {
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
        if (name == "FY21 New Faculty for Web.csv") {
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
        let casuri = "/_cascade/blocks/2020-faculty"
        var name:String = "test-uri-name"
        var sdnTitle:String = "test block title"
        var sdnName:String = "Test Name Goes Here"
        
        //0: Full Name
        //1: Title
        //2: Building
        //3: Phone
        //4: Email
        let firstName = "\(row[0])"
        let lastName = "\(row[1])"
        let fullCollegeName = "\(row[2])"
        let dept = "\(row[3])"
        let title = "\(row[4])"
        let degree = "\(row[5])"
        let institution = "\(row[6])"
        let pictured = "\(row[7])"
        let headshot = "\(row[1]).\(row[0]).png"
        name = "\(row[1])-\(row[0])"
        sdnName = "\(firstName) \(lastName)"
        sdnTitle = "\(title)"
        let sdnCollegeTitle = "\(title), \(dept)"
        var sdnHeadshotURL = "/img/2020/\(headshot)"
        let sdnEducation = "\(degree), \(institution)"
        let sdnStaffProfile = ""
        
        sdnHeadshotURL = sdnHeadshotURL.trimmingCharacters(in: .whitespacesAndNewlines)
        sdnHeadshotURL = sdnHeadshotURL.replacingOccurrences(of: " ", with: "")
        if (pictured == "not pictured") {
            sdnHeadshotURL = ""
        }
        
        print("casuri will be: \(casuri) \t\t name will be: \(name)")
        print("\t creating asset for profile \(name): \(sdnName)")
        print("\t\t \(sdnTitle)" )
        let assetObj = createBlockRequest(u:apiClient.username, p:apiClient.password, site:siteName, definitionPath: definitionPath, parentFolderPath: casuri, name: name, title: title, sdnHeadshotURL: sdnHeadshotURL, sdnName: sdnName, sdnCollegeTitle: sdnCollegeTitle, sdnTitle: sdnTitle, sdnEducation:sdnEducation, sdnStaffProfile: sdnStaffProfile, tags:["2020", fullCollegeName])
        return assetObj
    }
    
    public func createBlockRequest(u:String, p:String, site:String, definitionPath:String, parentFolderPath:String, name:String, title:String, sdnHeadshotURL:String, sdnName:String, sdnCollegeTitle:String, sdnTitle:String, sdnEducation:String, sdnStaffProfile:String, tags:[String]) ->
        CreateBlockRequest {
            var brequest:CreateBlockRequest
            let md:Metadata = Metadata(displayName:sdnName, title:sdnName)
            //, startDate: nil)
            let auth:Authentication = Authentication(username: u, password: p)
            var sdn:StructuredData = StructuredData(structuredDataNodes: [], definitionPath: nil)
            //let docStr:String = try doc.body()!.html().htmlEscape(allowUnsafeSymbols:true)
            let sdnCollegeTitleTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "college-title", text:sdnCollegeTitle, structuredDataNodes: nil, filePath: nil, assetType:nil)
            let sdnTitleTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "title", text: sdnTitle, structuredDataNodes: nil, filePath: nil, assetType: nil)
            let educationTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "education", text: sdnEducation, structuredDataNodes: nil, filePath: nil, assetType: nil)
            let sdnStaffProfileTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "staffProfile", text: sdnStaffProfile, structuredDataNodes: nil, filePath: nil, assetType: nil)
            let headshotFType:StructuredDataNode = StructuredDataNode(type: "asset", identifier: "headshot", text: nil, structuredDataNodes: nil, filePath:sdnHeadshotURL, assetType:"file")

            let smGroup:StructuredDataNode = StructuredDataNode(type: "group", identifier: "staffMember", text: nil, structuredDataNodes: [headshotFType, sdnTitleTType, sdnCollegeTitleTType, educationTType, sdnStaffProfileTType], filePath: nil, assetType: nil)
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
