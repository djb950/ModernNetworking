//
//  File.swift
//  
//
//  Created by DJ A on 8/4/23.
//

import Foundation

struct CatFact: Codable, Equatable {
    static func == (lhs: CatFact, rhs: CatFact) -> Bool {
        return lhs._id == rhs._id
    }
    
    struct CatFactStatus: Codable {
        let verified: Bool
        let sentCount: Int
    }
    
    let status: CatFactStatus
    let _id: String
    let user: String
    let text: String
    let __v: Int
    let source: String
    let updatedAt: String
    let type: String
    let createdAt: String
    let deleted: Bool
    let used: Bool
}
