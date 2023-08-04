//
//  File.swift
//  
//
//  Created by DJ A on 8/4/23.
//

import Foundation

public enum HTTPStatusCode {
    init?(rawValue: Int) {
        switch rawValue {
        case 100...199:
            self = .info
        case 200...299:
            self = .success
        case 300...399:
            self = .redirect
        case 400...499:
            self = .clientError
        case 500...599:
            self = .serverError
        default:
            self = .unknown
        }
    }
    
    case info
    case success
    case redirect
    case clientError
    case serverError
    case unknown
    
    var failureCode: RequestError? {
        switch self {
        case .info:
            return .unknown
        case .success:
            return nil
        case .redirect:
            return .unknown
        case .clientError:
            return .decodingError
        case .serverError:
            return .serverError
        case .unknown:
            return .unknown
        }
    }
}
