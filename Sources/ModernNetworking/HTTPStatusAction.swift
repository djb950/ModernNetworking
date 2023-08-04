//
//  File.swift
//  
//
//  Created by DJ A on 8/4/23.
//

import Foundation

/**
 An enum stating what should happen for a particular HTTP response code
 */
public enum HTTPStatusAction<T: Codable>: Equatable where T: Equatable {
    case fail
    case decodeResponse(T)
}
