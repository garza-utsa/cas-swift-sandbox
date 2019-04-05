//
//  PostSearch.swift
//  SwiftSoup
//
//  Created by John David Garza on 4/4/19.
//

import Foundation

public struct PostDelete: APIRequest {
    public typealias Response = DeleteResponse
    
    public var resourceName: String {
        return "delete"
    }
}
