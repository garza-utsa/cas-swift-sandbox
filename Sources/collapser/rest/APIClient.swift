//
//  APIClient.swift
//  collapser
//
//  Created by John David Garza on 2/19/19.
//
import Foundation

public class APIClient {
    private let MAX_CONCURRENT_OPERATION_COUNT = 50
    private let internalQueue: DispatchQueue
    public let oq:OperationQueue = OperationQueue()
    public var completedOperations:Int = 0
    private let baseEndpointURL:URL
    private let session = URLSession(configuration: .default)
    public let username: String
    public let password: String
    public var state:Int {
        get {
            return internalQueue.sync { completedOperations }
        }
        set (newState) {
            internalQueue.sync { completedOperations = newState }
        }
    }

    public init(baseEndpointURL:URL, username: String, password: String) {
        self.baseEndpointURL = baseEndpointURL
        self.username = username
        self.password = password
        self.internalQueue = DispatchQueue(label: "edu.utsa.vpaa.cascade.internal")
        self.oq.maxConcurrentOperationCount = MAX_CONCURRENT_OPERATION_COUNT
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
                    if let creationID = apiResponse.createdAssetId {
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
        let syncQueue:DispatchQueue = DispatchQueue(label: "edu.utsa.vpaa.cascade", qos: .utility)
        let semaphore:DispatchSemaphore = DispatchSemaphore(value: 0)
        let endpoint = self.endpoint(for: request)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload
        self.oq.addOperation {
            syncQueue.async{
                let task = self.session.dataTask(with: request) { data, response, error in
                    if let data = data {
                        do {
                            self.state = self.state + 1
                            let apiResponse = try
                                JSONDecoder().decode(APIResponse<T.Response>.self, from: data)
                            //print(String(decoding: data, as: UTF8.self))
                            if apiResponse.createdAssetId != nil {
                                //print("api client recv'd \(apiResponse.createdAssetId ?? "") from POST request")
                                print("sucess: \(self.state)")
                                completion(.success(apiResponse))
                            } else if let message = apiResponse.message {
                                //print(path, name)
                                print("failure: \(self.state)")
                                completion(.failure(APIError.server(message: "server failed asset creation \(message)")))
                            } else {
                                print("failure: \(self.state)")
                                //print(String(data: data, encoding: .utf8)!)
                                completion(.failure(APIError.decoding))
                                //completion(.failure(APIError.decoding))
                            }
                        } catch {
                            print("failure: \(self.state)")
                            print("JSONDECODE Failed")
                            completion(.failure(error))
                        }
                    } else if let error = error {
                        print("failure: \(self.state)")
                        completion(.failure(error))
                    }
                }
                task.resume()
            }
            _ = semaphore.wait(timeout: .now() + 3)
        }
    }
    
    /// Encodes a URL based on the given request
    /// Everything needed for a public request to Marvel servers is encoded directly in this URL
    private func endpoint<T: APIRequest>(for request: T) -> URL {
        guard let baseUrl = URL(string: request.resourceName, relativeTo: baseEndpointURL) else {
            fatalError("Bad resourceName: \(request.resourceName)")
        }
        var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true)!
        // Auth query items needed for all api requests
        /*
        let commonQueryItems = [
            URLQueryItem(name: "u", value: username),
            URLQueryItem(name: "p", value: password)]
        */
        // Custom query items needed for this specific request
        let customQueryItems: [URLQueryItem]
        do {
            customQueryItems = try URLQueryItemEncoder.encode(request)
        } catch {
            fatalError("Wrong parameters: \(error)")
        }
        // + commonQueryItems
        components.queryItems = customQueryItems
        // Construct the final URL with all the previous data
        return components.url!
    }
}
