//
//  Asset.swift
//  collapser
//
//  Created by John David Garza on 2/18/19.
//

import Foundation
import SwiftSoup

struct CreateRequest : Codable {
    let asset:Asset
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

struct CreateResponse : Codable {
    let createdAssetId:String
    let success:String
}

func createAssetRequest(title:String, parentFolderPath:String, name:String, doc:Document) -> CreateRequest {
    let md:Metadata = Metadata(displayName:title, title:title)
    let rowNode:StructuredDataNode = StructuredDataNode(type: "group", identifier: "row", text:nil, structuredDataNodes: nil)
    let sdn:StructuredData = StructuredData(structuredDataNodes: [rowNode])
    let p:Page = Page(contentTypePath: "ROOT Global Page - Content Rows",
                      structuredData:sdn,
                      metadata: md,
                      parentFolderPath: parentFolderPath,
                      siteName: "GLOBAL-WWWROOT",
                      name: name)
    let a:Asset = Asset(page: p)
    let arequest:CreateRequest = CreateRequest(asset: a)
    return arequest
}
