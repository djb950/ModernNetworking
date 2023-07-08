//
//  File.swift
//  
//
//  Created by DJ A on 7/8/23.
//

import Foundation

/**
 An enum representing the different reasons a network request could fail
 */
public enum RequestError: Error {
    case badRequest
    case serverError
    case unknown
    case decodingError
    
    var message: String {
        switch self {
        case .badRequest:
            return "Something is wrong with your request. Please check everything is correct and try again."
        case .serverError:
            return "There was a server error when making the request."
        case .unknown:
            return "An unknown error occurred when making your request"
        case .decodingError:
            return "Error decoding JSON"
        }
    }
}
