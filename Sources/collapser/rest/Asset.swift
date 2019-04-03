//
//  Asset.swift
//  collapser
//
//  Created by John David Garza on 2/18/19.
//

import Foundation
import SwiftSoup

public struct CreateRequest : Codable {
    let authentication:Authentication
    let asset:Asset
}

struct Authentication : Codable {
    let username: String
    let password: String
}

struct Asset : Codable {
    let page: Page
}

struct Page : Codable {
    let contentTypePath:String
    let structuredData:StructuredData
    let metadata:Metadata
    let parentFolderPath:String
    let siteName:String
    let name:String
}

struct StructuredData : Codable {
    let structuredDataNodes:[StructuredDataNode]
}

struct StructuredDataNode : Codable {
    let type:String
    let identifier:String
    let text:String?
    let structuredDataNodes:[StructuredDataNode]?
}

struct Metadata : Codable {
    let displayName:String
    let title:String
}

public struct CreateResponse : Codable {
    let createdAssetId:String?
    let success:Bool?
    let message:String?
}

public func createAssetRequest(u:String, p:String, site:String, contentType:String, title:String, parentFolderPath:String, name:String, doc:Document) -> CreateRequest {
    var arequest:CreateRequest
    let md:Metadata = Metadata(displayName:title, title:title)
    let auth:Authentication = Authentication(username: u, password: p)
    var sdn:StructuredData = StructuredData(structuredDataNodes: [])
    do {
        let docStr:String = try doc.body()!.html()
        let textType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "type", text: "WYSIWYG", structuredDataNodes: nil)
        let textEditor:StructuredDataNode = try StructuredDataNode(type: "text", identifier: "editor", text: docStr, structuredDataNodes: nil)
        let columnNode:StructuredDataNode = StructuredDataNode(type: "group", identifier: "column", text: nil, structuredDataNodes: [textType, textEditor])
        let rowNode:StructuredDataNode = StructuredDataNode(type: "group", identifier: "row", text:nil, structuredDataNodes: [columnNode])
        sdn = StructuredData(structuredDataNodes: [rowNode])
    } catch Exception.Error(let type, let message) {
        print("Error while trying to parse snippet from \(doc)")
        print("\(type):\(message)")
    } catch {
        print("***ERROR***")
    }
    let p:Page = Page(contentTypePath: contentType,
                      structuredData:sdn,
                      metadata: md,
                      parentFolderPath: parentFolderPath,
                      siteName: site,
                      name: name)
    let a:Asset = Asset(page: p)
    arequest = CreateRequest(authentication: auth, asset: a)
    return arequest
}
