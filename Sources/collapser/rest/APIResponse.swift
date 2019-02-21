import Foundation

/// Top level response for every request to the Marvel API
/// Everything in the API seems to be optional, so we cannot rely on having values here
public struct APIResponse<Response: Decodable>: Codable {
    /// Whether it was ok or not
    public let success: Bool?
    public let createdAssetId: String?
    public let message: String?
}
