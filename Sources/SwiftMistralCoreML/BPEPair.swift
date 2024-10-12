//
//  BPEEncoder.swift
//  SwiftMistralCoreML
//
//  Created by Oscar Cardona on 30/9/24.
//


import Foundation

struct BPEPair: Hashable {
    let first: String
    let second: String
}

public final class BPEEncoder {
    private let encoder: [String: Int]
    let decoder: [Int: String]
    private let bpeRanks: [BPEPair: Int]
    private let cache = NSCache<NSString, NSArray>()
    
    let unkToken: String
    let unkTokenID: Int
    
    private let tokenPattern = "(\\[/?[A-Z_]+\\])|(<<[^>]+>>)|(<[^>]+>)|(\\s+)|(\\S+)"
    
    public init(tokenizerParser: TokenizerParser) {
        self.encoder = tokenizerParser.encoder
        self.decoder = tokenizerParser.decoder
        
        var bpeRanks: [BPEPair: Int] = [:]
        for (key, value) in tokenizerParser.bpeRanks {
            let pair = key.split(separator: " ").map { String($0) }
            if pair.count == 2 {
                let bpePair = BPEPair(first: pair[0], second: pair[1])
                bpeRanks[bpePair] = value
            }
        }
        self.bpeRanks = bpeRanks
        
        self.unkToken = tokenizerParser.unkToken
        self.unkTokenID = tokenizerParser.encoder[tokenizerParser.unkToken] ?? 0
    }
    
    func encode(text: String) -> [Int] {
        var tokens = [Int]()
        
        guard let regex = try? NSRegularExpression(pattern: tokenPattern, options: []) else { return [0]}
        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            if match.range(at: 1).location != NSNotFound { // Special token like [INST]
                let specialToken = text[Range(match.range(at: 1), in: text)!]
                if let tokenID = encoder[String(specialToken)] {
                    tokens.append(tokenID)
                } else {
                    tokens.append(unkTokenID)
                }
            } else if match.range(at: 2).location != NSNotFound { // Special token like <<SYS>>
                let specialToken = text[Range(match.range(at: 2), in: text)!]
                if let tokenID = encoder[String(specialToken)] {
                    tokens.append(tokenID)
                } else {
                    tokens.append(unkTokenID)
                }
            } else if match.range(at: 3).location != NSNotFound { // Special token like <s>
                let specialToken = text[Range(match.range(at: 3), in: text)!]
                if let tokenID = encoder[String(specialToken)] {
                    tokens.append(tokenID)
                } else {
                    tokens.append(unkTokenID)
                }
            } else if match.range(at: 4).location != NSNotFound { // Spaces
                continue
            } else if match.range(at: 5).location != NSNotFound { // General word/token
                var wordSubstring = text[Range(match.range(at: 5), in: text)!]
                
                if !wordSubstring.hasPrefix("▁") {
                    wordSubstring = "▁" + wordSubstring
                }
                
                if let tokenID = encoder[String(wordSubstring)] {
                    tokens.append(tokenID)
                } else {
                    let bpeTokens = bpe(token: Substring(wordSubstring))
                    for bpeToken in bpeTokens.split(separator: " ") {
                        if let tokenID = encoder[String(bpeToken)] {
                            tokens.append(tokenID)
                        } else {
                            tokens.append(unkTokenID)
                        }
                    }
                }
            }
        }
        
        return tokens
    }
    
    func decode(tokenIDs: [Int]) -> String {
        var text = ""
        for tokenID in tokenIDs {
            if let token = decoder[tokenID] {
                text += token
            }
        }
        return text
    }
    
    private func bpe(token: Substring) -> String {
        if let cached = cache.object(forKey: String(token) as NSString) as? [String] {
            return cached.joined(separator: " ")
        }
        
        var word = Array(token).map { String($0) }
        var pairs = getPairs(word: word)
        
        while true {
            let minPair = pairs.compactMap { pair -> (BPEPair, Int)? in
                if let rank = bpeRanks[pair] {
                    return (pair, rank)
                } else {
                    return nil
                }
            }.min(by: { $0.1 < $1.1 })
            
            guard let (bestPair, _) = minPair else { break }
            
            let (first, second) = (bestPair.first, bestPair.second)
            var newWord = [String]()
            var i = 0
            while i < word.count {
                if i < word.count - 1 && word[i] == first && word[i + 1] == second {
                    newWord.append(first + second)
                    i += 2
                } else {
                    newWord.append(word[i])
                    i += 1
                }
            }
            word = newWord
            if word.count == 1 {
                break
            } else {
                pairs = getPairs(word: word)
            }
        }
        
        let result = word.joined(separator: " ")
        cache.setObject(word as NSArray, forKey: String(token) as NSString)
        return result
    }
    
    private func getPairs(word: [String]) -> Set<BPEPair> {
        var pairs = Set<BPEPair>()
        for i in 0..<word.count - 1 {
            let pair = BPEPair(first: word[i], second: word[i + 1])
            pairs.insert(pair)
        }
        return pairs
    }
}
