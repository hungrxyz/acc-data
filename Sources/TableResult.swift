//
//  TableResult.swift
//  ACC
//
//  Created by marko on 10/26/23.
//

import Foundation

struct TableResult: Encodable {
    
    let position: String
    let id: String
    let name: String
    let club: String
    let age: Int
    let numberOfRaces: Int
    let totalPoints: Int
    let pointsPerRace: [Int?]

}
