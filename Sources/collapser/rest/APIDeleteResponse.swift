import Foundation

/// Top level response for every request to the Marvel API
/// Everything in the API seems to be optional, so we cannot rely on having values here
public struct APIDeleteResponse<Response: Decodable>: Codable {
    /// Whether it was ok or not
    public let success: Bool?
    public let message: String?
}

