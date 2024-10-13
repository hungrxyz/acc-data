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

        enum Category: String, CaseIterable {
            case ja, jb, jc, c, d, b, a, x
            
            var gid: String {
                switch self {
                case .ja:
                    return "1745581134"
                case .jb:
                    return "906167346"
                case .jc:
                    return "294852544"
                case .c:
                    return "1292329851"
                case .d:
                    return "944348773"
                case .b:
                    return "563556052"
                case .a:
                    return "1908651275"
                case .x:
                    return "209563100"
                }
            }
        }

        for category in Category.allCases {

            let url = URL(string: "https://docs.google.com/spreadsheets/u/1/d/1oijJwAD6PN6DjnABpWXxOqVjFoFUsf7l4Jzt-uiHOmc/pubhtml/sheet?headers=false&gid=\(category.gid)")!
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
                .appendingPathComponent("2024")
                .appendingPathComponent("standings")
            try fileManager.createDirectory(at: standingsURL, withIntermediateDirectories: true)

            let aURL = standingsURL.appendingPathComponent("\(category.rawValue).json")
            let jsonData = try JSONEncoder().encode(results)

            fileManager.createFile(atPath: aURL.path, contents: jsonData)
        }

    }

}
