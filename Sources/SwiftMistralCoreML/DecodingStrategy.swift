//
//  DecodingStrategy.swift
//  SwiftMistralCoreML
//
//  Created by Oscar Cardona on 8/10/24.
//

import Foundation
import CoreML


protocol DecodingStrategy: Sendable {
    func nextToken(logitsArray: MLMultiArray) throws -> Int
}

public enum DecodingAlgorithm: String, CaseIterable, Sendable {
    case greedy = "Greedy"
    case topK = "TopK"
}

struct GreedyDecodingStrategy: DecodingStrategy {
    func nextToken(logitsArray: MLMultiArray) throws -> Int {
        let lastTokenIndex = logitsArray.shape[1].intValue - 1
        var maxLogitValue: Float = -Float.infinity
        var maxLogitIndex: Int = 0
        let vocabSize = logitsArray.shape[2].intValue
        
        for vocabIndex in 0..<vocabSize {
            let currentLogit = logitsArray[[0, NSNumber(value: lastTokenIndex), NSNumber(value: vocabIndex)] as [NSNumber]].floatValue
            if currentLogit > maxLogitValue {
                maxLogitValue = currentLogit
                maxLogitIndex = vocabIndex
            }
        }
        
        return maxLogitIndex
    }
}

struct TopKDecodingStrategy: DecodingStrategy {
    let topK: Int
    
    func nextToken(logitsArray: MLMultiArray) throws -> Int {
        let lastTokenIndex = logitsArray.shape[1].intValue - 1
        let vocabSize = logitsArray.shape[2].intValue
        
        var logits: [Float] = []
        for vocabIndex in 0..<vocabSize {
            let index = [0, NSNumber(value: lastTokenIndex), NSNumber(value: vocabIndex)] as [NSNumber]
            let logit = logitsArray[index].floatValue
            logits.append(logit)
        }
        
        let topKIndices = Array(logits.enumerated().sorted(by: { $0.element > $1.element }).prefix(topK).map { $0.offset })
        let topKLogits = topKIndices.map { logits[$0] }
        
        let probabilities = softmax(topKLogits)
        let sampledIndex = randomSample(probabilities: probabilities)
        
        return topKIndices[sampledIndex]
    }
    
    private func softmax(_ logits: [Float]) -> [Float] {
        let maxLogit = logits.max() ?? 0.0
        let exps = logits.map { exp($0 - maxLogit) }
        let sumExps = exps.reduce(0, +)
        return exps.map { $0 / sumExps }
    }
    
    private func randomSample(probabilities: [Float]) -> Int {
        let cumulativeProbabilities = probabilities.reduce(into: [Float]()) { result, prob in
            let cumulative = (result.last ?? 0) + prob
            result.append(cumulative)
        }
        
        let randomValue = Float.random(in: 0..<1)
        for (index, cumulativeProbability) in cumulativeProbabilities.enumerated() {
            if randomValue < cumulativeProbability {
                return index
            }
        }
        
        return probabilities.count - 1
    }
}
