//
//  APIClient.swift
//  collapser
//
//  Created by John David Garza on 2/19/19.
//
import Foundation

public class APIClient {
    private let baseEndpointUrl = URL(string: "https://walledev.it.utsa.edu:443/api/v1/")!
    private let session = URLSession(configuration: .default)
    private let username: String
    private let password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    /// Sends a request to the server, calling the completion method when finished
    public func send<T: APIRequest>(_ request: T, completion: @escaping ResultCallback<APIResponse<T.Response>>) {
        let endpoint = self.endpoint(for: request)
        
        let task = session.dataTask(with: URLRequest(url: endpoint)) { data, response, error in
            if let data = data {
                do {
                    // Decode the top level response, and look up the decoded response to see
                    // if it's a success or a failure
                    let apiResponse = try
                        JSONDecoder().decode(APIResponse<T.Response>.self, from: data)
                    if let creationID = apiResponse.createAssetID {
                        print("api client recv'd \(creationID) from POST request")
                        completion(.success(apiResponse))
                    } else if let message = apiResponse.success {
                        completion(.failure(APIError.server(message: "server failed asset creation \(message)")))
                    } else {
                        completion(.failure(APIError.decoding))
                    }
                } catch {
                    completion(.failure(error))
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    public func post<T: APIRequest>(_ request: T, payload: Data, path: String, name: String, completion: @escaping ResultCallback<APIResponse<T.Response>>) {
        let endpoint = self.endpoint(for: request)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload
        //print(\(payload))
        let task = session.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    // Decode the top level response, and look up the decoded response to see
                    // if it's a success or a failure
                    let apiResponse = try
                        JSONDecoder().decode(APIResponse<T.Response>.self, from: data)
                    if apiResponse.createAssetID != nil {
                        //print("api client recv'd \(creationID) from POST request")
                        completion(.success(apiResponse))
                    } else if let message = apiResponse.message {
                        //print(path, name)
                        completion(.failure(APIError.server(message: "server failed asset creation \(message)")))
                    } else {
                        //print(path, name)
                        //print("response was: \(String(describing: data))")
                        //print(String(data: data, encoding: .utf8)!)
                        completion(.failure(APIError.decoding))
                        //completion(.failure(APIError.decoding))
                    }
                } catch {
                    print("JSONDECODE Failed")
                    completion(.failure(error))
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    /// Encodes a URL based on the given request
    /// Everything needed for a public request to Marvel servers is encoded directly in this URL
    private func endpoint<T: APIRequest>(for request: T) -> URL {
        guard let baseUrl = URL(string: request.resourceName, relativeTo: baseEndpointUrl) else {
            fatalError("Bad resourceName: \(request.resourceName)")
        }
        var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true)!
        // Auth query items needed for all api requests
        let commonQueryItems = [
            URLQueryItem(name: "u", value: username),
            URLQueryItem(name: "p", value: password)]
        // Custom query items needed for this specific request
        let customQueryItems: [URLQueryItem]
        do {
            customQueryItems = try URLQueryItemEncoder.encode(request)
        } catch {
            fatalError("Wrong parameters: \(error)")
        }
        components.queryItems = commonQueryItems + customQueryItems
        // Construct the final URL with all the previous data
        return components.url!
    }
}
