//
// ModernNetworking.swift
//
// Copyright (c) 2023 David Brunk
//

import Foundation

public protocol NetworkManagerProtocol {
    func request<T: Codable>(endpoint: DummyEndpoint, requestMethod: HTTPMethod, responseType: T.Type, customDecoder: JSONDecoder?, statusCodeActions: [HTTPStatusCode: HTTPStatusAction<T>]) async throws -> T?
    func buildRequest(requestMethod: HTTPMethod, endpoint: DummyEndpoint, headers: [String:String]) -> URLRequest?
    func handleRequestResponse<T: Codable>(decoding responseType: T.Type, from data: Data, for statusCode: HTTPStatusCode, with customDecoder: JSONDecoder?, statusCodeActions: [HTTPStatusCode: HTTPStatusAction<T>]) throws -> T
}

open class NetworkManager: NetworkManagerProtocol {
    
    // MARK: Helper functions

    /**
         Builds out a request to be used in our network calls
         - Parameter requestMethod: The type of `HTTPMethod`
         - Parameter endpoint: A `LudusEndpoint` to be used in the network call
         - Parameter headers: A dictionary `[String:String]` of headers  to be added to the request
         - Returns: A `URLRequest` object, or nil if the request was not able to be built.
         */
    public func buildRequest(requestMethod: HTTPMethod, endpoint: DummyEndpoint, headers: [String:String] = [:]) -> URLRequest? {
            let urlString = endpoint.rawValue
            guard var components = URLComponents(string: urlString) else { return nil }
            switch requestMethod {
            case .get(let queryItems):
                components.queryItems = queryItems
            default:
                break
            }
            guard let url = components.url else { return nil }
            var request = URLRequest(url: url)
            switch requestMethod {
            case .post(let requestBody):
                let jsonString = requestBody?.reduce("") { "\($0)\($1.0)=\($1.1)&" }.dropLast()
                guard let jsonData = jsonString?.data(using: .utf8, allowLossyConversion: false) else { return nil }
                request.httpBody = jsonData
            default:
                break
            }
            request.httpMethod = requestMethod.stringValue
            request.allHTTPHeaderFields = headers
            return request
        }
        
        /**
         Generic function that handles decoding/error handling for network calls
         - Parameter responseType: `T`; A `Codable` type to be decoded in the event of a successful request
         - Parameter data: The `Data` to be decoded
         - Parameter statusCode: An `Int` indicating the status code of the network request. This is switched on to determine how we handle the result
         - Parameter customDecoder: You can pass in a `JSONDecoder` that you have preconfigured to gain more granular control over how the response is decoded. Defaults to nil and uses a default `JSONDecoder`
         - Returns: `T`; A generic `Codable` object
         - Throws: A `RequestError` indicating the reason that the request failed
         */
        public func handleRequestResponse<T: Codable>(decoding responseType: T.Type, from data: Data, for statusCode: HTTPStatusCode, with customDecoder: JSONDecoder? = nil, statusCodeActions: [HTTPStatusCode: HTTPStatusAction<T>] = [:]) throws -> T {
            switch statusCode {
            case .info:
                if let infoAction = statusCodeActions[.info]  {
                    if infoAction == .decodeResponse(responseType as! T) {
                        let decoder = customDecoder != nil ? customDecoder! : JSONDecoder()
                        return try decoder.decode(responseType, from: data)
                    } else if infoAction == .fail {
                        if let error = statusCode.failureCode {
                            throw error
                        } else {
                            throw RequestError.unknown
                        }
                    } else {
                        throw RequestError.unknown
                    }
                } else {
                    throw RequestError.unknown
                }
            case .success:
                if let okAction = statusCodeActions[.success] {
                    if okAction == .decodeResponse(responseType as! T) {
                        let decoder = customDecoder != nil ? customDecoder! : JSONDecoder()
                        return try decoder.decode(responseType, from: data)
                    } else if okAction == .fail {
                        if let error = statusCode.failureCode {
                            throw error
                        } else {
                            throw RequestError.unknown
                        }
                    } else {
                        throw RequestError.unknown
                    }
                    
                // 200 should default to be successful; decode
                } else {
                    let decoder = customDecoder != nil ? customDecoder! : JSONDecoder()
                    return try decoder.decode(responseType, from: data)
                }
            case .redirect:
                if let redirectAction = statusCodeActions[.redirect] {
                    if redirectAction == .decodeResponse(responseType as! T) {
                        let decoder = customDecoder != nil ? customDecoder! : JSONDecoder()
                        return try decoder.decode(responseType, from: data)
                    } else if redirectAction == .fail {
                        if let error = statusCode.failureCode {
                            throw error
                        } else {
                            throw RequestError.unknown
                        }
                    } else {
                        throw RequestError.unknown
                    }
                } else {
                    throw RequestError.unknown
                }
            case .clientError:
                if let clientErrorAction = statusCodeActions[.redirect] {
                    if clientErrorAction == .decodeResponse(responseType as! T) {
                        let decoder = customDecoder != nil ? customDecoder! : JSONDecoder()
                        return try decoder.decode(responseType, from: data)
                    } else if clientErrorAction == .fail {
                        if let error = statusCode.failureCode {
                            throw error
                        } else {
                            throw RequestError.unknown
                        }
                    } else {
                        throw RequestError.unknown
                    }
                } else {
                    throw RequestError.badRequest
                }
            case .serverError:
                if let serverErrorAction = statusCodeActions[.redirect] {
                    if serverErrorAction == .decodeResponse(responseType as! T) {
                        let decoder = customDecoder != nil ? customDecoder! : JSONDecoder()
                        return try decoder.decode(responseType, from: data)
                    } else if serverErrorAction == .fail {
                        if let error = statusCode.failureCode {
                            throw error
                        } else {
                            throw RequestError.unknown
                        }
                    } else {
                        throw RequestError.unknown
                    }
                } else {
                    throw RequestError.serverError
                }
            case .unknown:
                throw RequestError.unknown
            }
        }

    // MARK: Public functions

    /**
         Generic network request that allows the user control over what kind of request to make, which endpoint, and how to process the response.
         - Parameter endpoint: The `DummyEndpoint` to hit; ; You can substitute your own endpoint instead of this enum
         - Parameter requestMethod: An `HTTPMethod` that determines the type of request
         - Parameter responseType: The `Codable` object to be decoded from the request response
         - Parameter customDecoder: An optional `JSONDecoder` to be passed in to allow for more granular control of how the decoding process is executed. Defaults to `nil`
         - Returns: The decoded `T` `Codable` type, nil if the request fails
         - Throws: A `RequestError` corresponding to why the request failed
         */
        public func request<T: Codable>(endpoint: DummyEndpoint, requestMethod: HTTPMethod, responseType: T.Type, customDecoder: JSONDecoder? = nil, statusCodeActions: [HTTPStatusCode: HTTPStatusAction<T>] = [:]) async throws -> T? {
            guard let request = buildRequest(requestMethod: requestMethod, endpoint: endpoint) else { return nil }
            let (data, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse {
                do {
                    guard let statusCode = HTTPStatusCode(rawValue: response.statusCode) else { return nil }
                    return try handleRequestResponse(decoding: T.self, from: data, for: statusCode, with: customDecoder != nil ? customDecoder : nil, statusCodeActions: statusCodeActions)
                } catch(let error) {
                    throw error
                }
            } else {
                throw RequestError.unknown
            }
        }
}
