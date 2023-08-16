//
// ModernNetworking.swift
//
// Copyright (c) 2023 David Brunk
//

import Foundation

public protocol NetworkManagerProtocol {
    func request<T: Codable, E: RawRepresentable>(endpoint: E, requestMethod: HTTPMethod, responseType: T.Type, customDecoder: JSONDecoder?, statusCodeActions: [HTTPStatusCode: HTTPStatusAction<T>]) async throws -> T? where E.RawValue == String
    func buildRequest<E: RawRepresentable>(requestMethod: HTTPMethod, endpoint: E, headers: [String:String]) -> URLRequest? where E.RawValue == String
    func handleRequestResponse<T: Codable>(decoding responseType: T.Type, from data: Data, for statusCode: HTTPStatusCode, with customDecoder: JSONDecoder?, statusCodeActions: [HTTPStatusCode: HTTPStatusAction<T>]) throws -> T
}

open class NetworkManager: NetworkManagerProtocol {
    
    // MARK: Main Request Method
    
    /**
     This is the main method for making a network request. You must supply the HTTP request type, which endpoint you want to hit, and the a `Codable` response type. You may also supply a custom `JSONDecoder` for more granular control of the json decoding process, as well as status code actions for more granular control over what should happen for each http status code response.
     - Parameter endpoint: A generic endpoint constrained to `RawRepresentable`. Generally endpoints are created as an enum with each case representing a different endpoint
     - Parameter requestMethod: An `HTTPMethod` representing which kind of network request to make. i.e. GET, POST, etc.
     - Parameter responseType: A generic type constrained to `Codable` This is the object that will be decoded from the network response
     - Parameter customDecode: An optional `JSONDecoder` that allows more granular control over how the network response is decoded
     - Parameter statusCodeActions: A dictionary of `HTTPStatusCode` objects as keys and `HTTPStatusAction` as values. Passing values in for this parameter gives allows for customization of what should happen for each http status code. Defaults to an empty dictionary
     - Throws: A `RequestError` indicating why the request failed
     - Returns: A generic, optional `Codable` object
     */
    public func request<T: Codable, E: RawRepresentable>(endpoint: E, requestMethod: HTTPMethod, responseType: T.Type, customDecoder: JSONDecoder?, statusCodeActions: [HTTPStatusCode : HTTPStatusAction<T>] = [:]) async throws -> T? where E.RawValue == String {
        guard let request = buildRequest(requestMethod: requestMethod, endpoint: endpoint as! DummyEndpoint) else { return nil }
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
    
    // MARK: Helper functions

    /**
         Builds out a request to be used in our network calls
         - Parameter requestMethod: The type of `HTTPMethod`
         - Parameter endpoint: A `LudusEndpoint` to be used in the network call
         - Parameter headers: A dictionary `[String:String]` of headers  to be added to the request
         - Returns: A `URLRequest` object, or nil if the request was not able to be built.
         */
    public func buildRequest<E: RawRepresentable>(requestMethod: HTTPMethod, endpoint: E, headers: [String:String] = [:]) -> URLRequest? where E.RawValue == String {
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
//    public func request<T: Codable, E: RawRepresentable>(endpoint: E, requestMethod: HTTPMethod, responseType: T.Type, customDecoder: JSONDecoder? = nil, statusCodeActions: [HTTPStatusCode: HTTPStatusAction<T>] = [:]) async throws -> T? where E.RawValue == Int {
//        guard let request = buildRequest(requestMethod: requestMethod, endpoint: endpoint as! DummyEndpoint) else { return nil }
//            let (data, response) = try await URLSession.shared.data(for: request)
//            if let response = response as? HTTPURLResponse {
//                do {
//                    guard let statusCode = HTTPStatusCode(rawValue: response.statusCode) else { return nil }
//                    return try handleRequestResponse(decoding: T.self, from: data, for: statusCode, with: customDecoder != nil ? customDecoder : nil, statusCodeActions: statusCodeActions)
//                } catch(let error) {
//                    throw error
//                }
//            } else {
//                throw RequestError.unknown
//            }
//        }
}
