//public struct ModernNetworking {
//    public private(set) var text = "Hello, World!"
//
//    public init() {
//
//    }
//}

import Foundation

// MARK: Helper functions

/**
 Builds a network requests given certain specifications
 - Parameter url: A `String` representing the url the request should be made to
 - Parameter queryItems: Used for a GET request; this should be an array of `URLQueryItem` representing the parameters to be sent with the GET request.
        A default value of an empty array is provided.
 - Parameter requestBody: A dictionary representing request body parameters to be sent with a POST request. A default value of an empty dictionary is provided.
 - Parameter headers: A dictionary of HTTP headers to be sent with the request
 - Returns A `URLRequest` if successful, or nil otherwise
 */
private func buildRequest(for httpMethod: HTTPMethod, url: String, queryItems: [URLQueryItem] = [], requestBody: [String:Any] = [:], headers: [String:String] = [:]) -> URLRequest? {
    guard var components = URLComponents(string: url) else { return nil }
    if httpMethod == .get {
        components.queryItems = queryItems
    }
    guard let url = components.url else { return nil }
    var request = URLRequest(url: url)
    if httpMethod == .post {
        let jsonString = requestBody.reduce("") { "\($0)\($1.0)=\($1.1)&" }.dropLast()
        guard let jsonData = jsonString.data(using: .utf8, allowLossyConversion: false) else { return nil }
        request.httpBody = jsonData
    }
    request.httpMethod = httpMethod.stringValue
    request.allHTTPHeaderFields = headers
    return request
}

/**
 Handles the response of a network request. Specifically attempts to decode the specified `Codable` type, and throws an error if processing the request fails.
 - Parameter responseType: A `Codable` type to be decoded
 - Parameter data: The `Data` from the response that is to be decoded
 - Parameter statusCode: An `Int` representing the status code of the request response
 - Returns: A generic `Codable` type that was decoded successfully
 - Throws: A `RequestError` indicating the reason why the request or decoding of the response failed
 */
private func handleRequestResponse<T: Codable>(decoding responseType: T.Type, from data: Data, for statusCode: Int) throws -> T {
    switch statusCode {
    case 200:
        do {
            let apiResponse = try JSONDecoder().decode(T.self, from: data)
            return apiResponse
        } catch {
            throw RequestError.decodingError
        }
    case 400...499:
        throw RequestError.badRequest
    case 500...599:
        throw RequestError.serverError
    default:
        throw RequestError.unknown
    }
}

// MARK: Public functions

/**
 Makes a network request and returns a decoded `Codable` type if successful.
 - Parameter url: A `String` respresenting the url to make the request to
 - Parameter requestMethod: The kind of HTTP request to make (i.e. GET, POST, etc.)
 - Parameter queryItems: An array of `URLQueryItem` that can be specified for an `HTTPMethod.get` request. These will be added to the a `URLComponents` as `.queryItems`. By default, an empty array is provided
 - Parameter requestBody:A dictionary representing the request body parameters for an `HTTPMethod.post` request. These will be added to a `URLRequest` as `.httpBody`. By default, an empty dictionary is provided
 - Parameter headers: A dictionary representing the headers to be added to a `URLRequest`. By default, an empty dictionary is provided
 - Returns: A generic `Codable` type if succesfull, nil otherwise
 - Throws: A `RequestError` indicating the reason the request failed
 */
public func request<T: Codable>(url: String, requestMethod: HTTPMethod, responseType: T.Type, queryItems: [URLQueryItem] = [], requestBody: [String:Any] = [:], headers: [String:String] = [:]) async throws -> T? {
    guard let request = buildRequest(for: requestMethod, url: url) else { return nil }
    let (data, response) = try await URLSession.shared.data(for: request)
    if let response = response as? HTTPURLResponse {
        do {
            let decodedResponse = try handleRequestResponse(decoding: responseType, from: data, for: response.statusCode)
            return decodedResponse
        } catch(let error) {
            throw error
        }
    } else {
        throw RequestError.unknown
    }
}
