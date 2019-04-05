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

public struct CreateSearch : Codable {
    let authentication:Authentication
    let searchInformation:SearchInformation
}

public struct DeleteAsset : Codable {
    let authentication:Authentication
    let identifier:Identifier
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

struct SearchInformation : Codable {
    let searchTerms:String
    let siteName:String
    let searchFields:[String]
    let searchTypes:[String]
}

public struct CreateResponse : Codable {
    let createdAssetId:String?
    let success:Bool?
    let message:String?
}

public struct DeleteResponse : Codable {
    let success:Bool?
    let message:String?
}

struct Path : Codable {
    let path:String
    let siteId:String
    let siteName:String
}

public struct Match : Codable {
    let id:String
    let path:Path
    let type:String
    let recycled:Bool
}

public struct CreateSearchResponse : Codable {
    let matches:[Match]
    let success:Bool?
    let message:String?
}

public struct IDPath : Codable {
    let siteId:String
    let path:String
}

public struct Identifier : Codable {
    let type:String
    let path:IDPath
}

public func createDeleteRequest(u:String, p:String, match:Match) -> DeleteAsset {
    let deleteRequest:DeleteAsset
    let matchID = match.path
    let auth:Authentication = Authentication(username: u, password: p)
    let path:IDPath = IDPath(siteId: matchID.siteId, path: matchID.path)
    let id:Identifier = Identifier(type: match.type, path: path)
    deleteRequest = DeleteAsset(authentication: auth, identifier: id)
    return deleteRequest
}

public func createSearchRequest(u:String, p:String, searchTerms:String, siteName:String, searchFields:[String], searchTypes:[String]) -> CreateSearch {
    var searchRequest:CreateSearch
    let auth:Authentication = Authentication(username: u, password: p)
    let si:SearchInformation = SearchInformation(searchTerms: searchTerms, siteName: siteName, searchFields: searchFields, searchTypes: searchTypes)
    searchRequest = CreateSearch(authentication: auth, searchInformation: si)
    return searchRequest
}

public func createAssetRequest(u:String, p:String, site:String, contentType:String, title:String, parentFolderPath:String, name:String, doc:Document) -> CreateRequest {
    var arequest:CreateRequest
    let md:Metadata = Metadata(displayName:title, title:title)
    let auth:Authentication = Authentication(username: u, password: p)
    var sdn:StructuredData = StructuredData(structuredDataNodes: [])
    do {
        let docStr:String = try doc.body()!.html()
        let textType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "type", text: "WYSIWYG", structuredDataNodes: nil)
        let textEditor:StructuredDataNode = StructuredDataNode(type: "text", identifier: "editor", text: docStr, structuredDataNodes: nil)
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
