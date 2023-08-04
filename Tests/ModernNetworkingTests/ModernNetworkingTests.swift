import XCTest
@testable import ModernNetworking

public class NetworkManagerMock: NetworkManagerProtocol {
    public func buildRequest(requestMethod: ModernNetworking.HTTPMethod, endpoint: ModernNetworking.DummyEndpoint, headers: [String : String] = [:]) -> URLRequest? {
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
    
    public func handleRequestResponse<T>(decoding responseType: T.Type, from data: Data, for statusCode: ModernNetworking.HTTPStatusCode, with customDecoder: JSONDecoder? = nil, statusCodeActions: [ModernNetworking.HTTPStatusCode : ModernNetworking.HTTPStatusAction<T>] = [:]) throws -> T where T : Decodable, T : Encodable, T : Equatable {
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
    
    public func request<T>(endpoint: ModernNetworking.DummyEndpoint, requestMethod: ModernNetworking.HTTPMethod, responseType: T.Type, customDecoder: JSONDecoder? = nil, statusCodeActions: [ModernNetworking.HTTPStatusCode : ModernNetworking.HTTPStatusAction<T>] = [:]) async throws -> T? where T : Decodable, T : Encodable, T : Equatable {
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

final class ModernNetworkingTests: XCTestCase {
    
    var networkManagerMock: NetworkManagerMock?
    
    override func setUp() {
        networkManagerMock = NetworkManagerMock()
    }
    
    override func tearDown() {
        networkManagerMock = nil
    }
    
    func testFetchCatFacts() async throws {
        let catFacts = try await networkManagerMock?.request(endpoint: .catFacts, requestMethod: .get(queryItems: nil), responseType: [CatFact].self, customDecoder: nil)
        XCTAssertNotNil(catFacts)
    }
}
