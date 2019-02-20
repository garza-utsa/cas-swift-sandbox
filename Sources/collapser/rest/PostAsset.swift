//
//  PostAsset.swift
//  collapser
//
//  Created by John David Garza on 2/19/19.
//

import Foundation

public struct PostAsset: APIRequest {
    public typealias Response = CreateResponse
    
    public var resourceName: String {
        return "create"
    }
}
