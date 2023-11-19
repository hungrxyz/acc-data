// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import Foundation
import ArgumentParser
import SwiftSoup

@main
struct Scraper: AsyncParsableCommand {

    mutating func run() async throws {
        let url = URL(string: "https://docs.google.com/spreadsheets/u/1/d/e/2PACX-1vTxqu45sTCT3CtenEvlvuD9onGnyqwqNTOf-KMok2b9SPQ_ckVkvO7vuDraTaApwaJmwercGWYB-eiA/pubhtml/sheet?headers=false&gid=1908651275")!
        let (data, _) = try await URLSession.shared.data(from: url)

        let string = String(decoding: data, as: UTF8.self)

        let rows = try SwiftSoup
            .parse(string).select("tbody")
            .first()!.select("tr")
            .dropFirst(2)

        let entries = rows.reduce(into: [[String]]()) { partialResult, row in
            let values = (try? row.select("td").compactMap { try? $0.text() }) ?? []

            if values.isEmpty == false {
                partialResult.append(values)
            }
        }

        let results = entries.reduce(into: [TableResult]()) { partialResult, entry in
            var raw = entry

            let position = raw.removeFirst()
            let id = raw.removeFirst()

            guard id.isEmpty == false else { return }

            // Removing ID2
            raw.removeFirst()
            let name = raw.removeFirst()
            let club = raw.removeFirst()

            guard let age = Int(raw.removeFirst()),
                  let numberOfRaces = Int(raw.removeFirst()),
                  let totalPoints = Int(raw.removeFirst()) else {
                return
            }

            let pointsPerRace = raw.map { Int($0) }

            let result = TableResult(
                position: position,
                id: id,
                name: name,
                club: club,
                age: age,
                numberOfRaces: numberOfRaces,
                totalPoints: totalPoints,
                pointsPerRace: pointsPerRace
            )

            partialResult.append(result)
        }

        let fileManager = FileManager.default
        let standingsURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
            .appendingPathComponent("data")
            .appendingPathComponent("2023")
            .appendingPathComponent("standings")
        try fileManager.createDirectory(at: standingsURL, withIntermediateDirectories: true)

        let aURL = standingsURL.appendingPathComponent("a.json")
        let jsonData = try JSONEncoder().encode(results)
        
        fileManager.createFile(atPath: aURL.path, contents: jsonData)
    }

}
