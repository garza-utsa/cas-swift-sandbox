//
//  PostSearch.swift
//  SwiftSoup
//
//  Created by John David Garza on 4/4/19.
//

import Foundation

public struct PostSearch: APIRequest {
    public typealias Response = CreateSearchResponse
    
    public var resourceName: String {
        return "search"
    }
}
