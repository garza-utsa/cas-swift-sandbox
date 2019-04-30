//
//  searcher.swift
//  collapser
//
//  Created by John David Garza on 4/4/19.
//

import Foundation

struct Searcher {
    let searchTerm:String
    let siteName:String
    let searchFields:[String]
    let searchTypes:[String]
    let apiClient:APIClient
    var count:Int = 0
    
    init(client:APIClient, searchTerm:String, siteName:String, searchFields:[String], searchTypes:[String]) {
        self.apiClient = client
        self.searchTerm = searchTerm
        self.siteName = siteName
        self.searchFields = searchFields
        self.searchTypes = searchTypes
    }
    
    func search() -> [Match]? {
        var matches:[Match]?
        do {
            let searchObj = createSearchRequest(u: apiClient.username, p: apiClient.password, searchTerms: searchTerm, siteName: siteName, searchFields: searchFields, searchTypes: searchTypes)
            let encoder = JSONEncoder()
            let encodedSearch = try encoder.encode(searchObj)
            self.apiClient.postSearch(PostSearch(), payload: encodedSearch) {
                response in
                switch response {
                case .success(let response):
                    matches = response.matches
                    print("found \(matches!.count) matches")
                case .failure(let error):
                    print("****SERACH POST FAILED****")
                    print(error)
                }
            }
        } catch {
            print("***ERROR***")
        }
        return matches
    }
    
    func searchAndDestroy() {
        let encoder = JSONEncoder()
        let searchObj = createSearchRequest(u: apiClient.username, p: apiClient.password, searchTerms: searchTerm, siteName: siteName, searchFields: searchFields, searchTypes: searchTypes)
        do {
            let encodedSearch = try encoder.encode(searchObj)
            self.apiClient.postSearch(PostSearch(), payload: encodedSearch) {
                response in
                switch response {
                case .success(let response):
                    print("found \(response.matches!.count) matches")
                    let destroyCount = self.destroy(matches:response.matches!)
                    print("deleted \(destroyCount) matches")
                case .failure(let error):
                    print("****SERACH POST FAILED****")
                    print(error)
                }
            }
        } catch {
            print("***ERROR***")
        }
    }
    
    func destroy(matches:[Match]) -> Int {
        let encoder = JSONEncoder()
        var internalCount = 0
        do {
            for match in matches {
                internalCount = internalCount + 1
                let deleteObj = createDeleteRequest(u: self.apiClient.username, p: self.apiClient.password, match: match)
                let encodedDelete = try encoder.encode(deleteObj)
                self.apiClient.postDelete(PostDelete(), payload:encodedDelete) {
                    response in
                    switch response {
                    case .success(_):
                        print("deleted asset")
                    case .failure(let error):
                        print("failed to delete asset")
                        print(error)
                    }
                }
            }
        } catch {
            print("***ERROR***")
        }
        return internalCount
    }
}
