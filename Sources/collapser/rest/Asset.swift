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
    let asset:PageAsset
}

public struct CreateBlockRequest: Codable {
    let authentication:Authentication
    let asset:BlockAsset
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

struct PageAsset: Codable {
    let page: Page
}

struct BlockAsset: Codable {
    let xhtmlDataDefinitionBlock: xhtmlDataDefinitionBlock
}

struct Page : Codable {
    let contentTypePath:String
    let structuredData:StructuredData
    let metadata:Metadata
    let parentFolderPath:String
    let siteName:String
    let name:String
}

struct xhtmlDataDefinitionBlock : Codable {
    let structuredData:StructuredData
    let metadata:Metadata
    let parentFolderPath:String
    let siteName:String
    let name:String
    let tags:[CascadeTag]
}

struct CascadeTag : Codable {
    let name:String
}

struct StructuredData : Codable {
    let structuredDataNodes:[StructuredDataNode]
    let definitionPath:String?
}

struct StructuredDataNode : Codable {
    let type:String
    let identifier:String
    let text:String?
    let structuredDataNodes:[StructuredDataNode]?
    let filePath:String?
    let assetType:String?
}

struct Metadata : Codable {
    let displayName:String
    let title:String
    let startDate:String?
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

/*
public func createBlockRequest(u:String, p:String, site:String, definitionPath:String, parentFolderPath:String, name:String, title:String, sdnHeadshotURL:String, sdnName:String, sdnCollegeTitle:String, sdnTitle:String, sdnEducation:String, sdnStaffProfile:String, tags:[String]) ->
    CreateBlockRequest {
    var brequest:CreateBlockRequest
    let md:Metadata = Metadata(displayName:title, title:title, startDate: nil)
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
 */

public func createBlockRequest(u:String, p:String, site:String, definitionPath:String, parentFolderPath:String, name:String, title:String, sdnName:String, sdnCollegeTitle:String, sdnTitle:String, sdnEducation:String, sdnStaffProfile:String, tags:[String]) ->
    CreateBlockRequest {
        var brequest:CreateBlockRequest
        let md:Metadata = Metadata(displayName:title, title:title, startDate: nil)
        let auth:Authentication = Authentication(username: u, password: p)
        var sdn:StructuredData = StructuredData(structuredDataNodes: [], definitionPath: nil)
        //let docStr:String = try doc.body()!.html().htmlEscape(allowUnsafeSymbols:true)
        let profileTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "staffProfile", text: sdnStaffProfile, structuredDataNodes: nil, filePath: nil, assetType: nil)
        let educationTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "education", text: sdnEducation, structuredDataNodes: nil, filePath: nil, assetType: nil)
        let titleTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "title", text: sdnTitle, structuredDataNodes: nil, filePath: nil, assetType: nil)
        let collegeTitleTType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "college-title", text: sdnCollegeTitle, structuredDataNodes: nil, filePath: nil, assetType: nil)
        let smGroup:StructuredDataNode = StructuredDataNode(type: "group", identifier: "staffMember", text: nil, structuredDataNodes: [collegeTitleTType, titleTType, educationTType, profileTType], filePath: nil, assetType: nil)
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

public func createAssetRequest(u:String, p:String, site:String, contentType:String, title:String, parentFolderPath:String, name:String, doc:Document) -> CreateRequest {
    var arequest:CreateRequest
    let md:Metadata = Metadata(displayName:title, title:title, startDate:"")
    let auth:Authentication = Authentication(username: u, password: p)
    var sdn:StructuredData = StructuredData(structuredDataNodes: [], definitionPath: nil)
    do {
        let docStr:String = try doc.body()!.html().htmlEscape(allowUnsafeSymbols:true)
        let textType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "type", text: "WYSIWYG", structuredDataNodes: nil, filePath: nil, assetType: nil)
        let textEditor:StructuredDataNode = StructuredDataNode(type: "text", identifier: "editor", text: docStr, structuredDataNodes: nil, filePath: nil, assetType: nil)
        let columnNode:StructuredDataNode = StructuredDataNode(type: "group", identifier: "column", text: nil, structuredDataNodes: [textType, textEditor], filePath: nil, assetType: nil)
        let rowNode:StructuredDataNode = StructuredDataNode(type: "group", identifier: "row", text:nil, structuredDataNodes: [columnNode], filePath: nil, assetType: nil)
        sdn = StructuredData(structuredDataNodes: [rowNode], definitionPath: nil)
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
    let a:PageAsset = PageAsset(page: p)
    arequest = CreateRequest(authentication: auth, asset: a)
    return arequest
}

public func createAssetRequest(u:String, p:String, site:String, contentType:String, title:String, parentFolderPath:String, name:String, doc:Document, date:Date) -> CreateRequest {
    var arequest:CreateRequest
    let df:DateFormatter = DateFormatter()
    df.dateFormat = "MMM d, yyyy, h:mm:ss a"
    let md:Metadata = Metadata(displayName:title, title:title, startDate:df.string(from:date))
    let auth:Authentication = Authentication(username: u, password: p)
    var sdn:StructuredData = StructuredData(structuredDataNodes: [], definitionPath: nil)
    do {
        let docStr:String = try doc.body()!.html().htmlEscape(allowUnsafeSymbols:true)
        let articleType:StructuredDataNode = StructuredDataNode(type: "text", identifier: "articleType", text: "custom", structuredDataNodes: nil, filePath: nil, assetType: nil)

        let textEditor:StructuredDataNode = StructuredDataNode(type: "text", identifier: "editor", text: docStr, structuredDataNodes: nil, filePath: nil, assetType: nil)
        let column:StructuredDataNode = StructuredDataNode(type: "group", identifier: "column", text: nil, structuredDataNodes: [textEditor], filePath: nil, assetType: nil)
        let contentRow:StructuredDataNode = StructuredDataNode(type: "group", identifier: "ContentRow", text: nil, structuredDataNodes: [column], filePath: nil, assetType: nil)
        
        sdn = StructuredData(structuredDataNodes: [articleType, contentRow], definitionPath: nil)
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
    let a:PageAsset = PageAsset(page: p)
    arequest = CreateRequest(authentication: auth, asset: a)
    return arequest
}
