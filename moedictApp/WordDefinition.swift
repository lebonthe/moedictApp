//
//  WordDefinition.swift
//  moedictApp
//
//  Created by Min Hu on 2023/12/22.
//

import Foundation

struct WordDefinition: Decodable {
    let title: String
    let radical: String?
    let non_radical_stroke_count: Int?
    let stroke_count: Int?
    let heteronyms: [Heteronym]
}

struct Heteronym: Decodable {
    let bopomofo: String
    let bopomofo2: String
    let pinyin: String
    let definitions: [Definition]
}

struct Definition: Decodable {
    let def: String
    let example: [String]?
    let type: String?
    let link: [String]?
}
