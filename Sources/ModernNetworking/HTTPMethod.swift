//
//  File.swift
//  
//
//  Created by DJ A on 7/8/23.
//

import Foundation

/**
 An enum representing the different types of HTTP request methods
 */
public enum HTTPMethod {
    case get
    case post
    case put
    case patch
    case delete
    case head
    
    var stringValue: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .put:
            return "PUT"
        case .patch:
            return "PATCH"
        case .delete:
            return "DELETE"
        case .head:
            return "HEAD"
        }
    }
}
