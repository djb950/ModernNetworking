//
//  File.swift
//  
//
//  Created by DJ A on 7/8/23.
//

import Foundation

public enum HTTPMethod: Equatable {
    public static func == (lhs: HTTPMethod, rhs: HTTPMethod) -> Bool {
        switch (lhs, rhs) {
        case (.get(let queryItems1), .get(queryItems: let queryItems2)):
            return queryItems1 == queryItems2
        case (.post(requestBody: let requestBody1), .post(requestBody: let requestBody2)):
            if let requestBody1, let requestBody2 {
                return requestBody1 == requestBody2
            } else if requestBody1 == nil && requestBody2 == nil {
                return true
            } else {
                return false
            }
        case (.post(requestBody: _), .get(queryItems: _)):
            return false
        case (.get(queryItems: _), .post(requestBody: _)):
            return false
        }
    }
    
    case get(queryItems: [URLQueryItem]?)
    case post(requestBody: [String:AnyHashable]?)
//    case put
//    case patch
//    case delete
//    case head
    
    var stringValue: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
//        case .put:
//            return "PUT"
//        case .patch:
//            return "PATCH"
//        case .delete:
//            return "DELETE"
//        case .head:
//            return "HEAD"
        }
    }
}
