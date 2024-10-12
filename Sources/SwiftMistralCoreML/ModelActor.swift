//
//  ModelActor.swift
//  SwiftMistralCoreML
//
//  Created by Oscar Cardona on 12/10/24.
//


import Foundation
import CoreML

actor ModelActor {
    private let model: StatefulMistral7BInstructInt4
    private var state: StatefulMistral7BInstructInt4State
    
    init() throws {
        do {
            self.model = try StatefulMistral7BInstructInt4(configuration: MLModelConfiguration())
        } catch {
            throw TextGeneratorError.missingMistral7B
        }
        self.state = model.makeState()
    }
    
    func generateNextToken(currentInputIds: [Int], decodingStrategy: DecodingStrategy) throws -> Int {
        let inputIdsArray = try createInputIdsArray(tokens: currentInputIds)
        let causalMaskArray = try createCausalMaskArray(sequenceLength: currentInputIds.count)
        let modelInput = StatefulMistral7BInstructInt4Input(inputIds: inputIdsArray, causalMask: causalMaskArray)
        
        let prediction: StatefulMistral7BInstructInt4Output
        do {
            prediction = try model.prediction(input: modelInput, using: self.state)
        } catch {
            throw TextGeneratorError.outputCastingError
        }
        
        return try decodingStrategy.nextToken(logitsArray: prediction.logits)
    }
    
    private func createInputIdsArray(tokens: [Int]) throws -> MLMultiArray {
        let sequenceLength = tokens.count
        guard let inputIdsArray = try? MLMultiArray(shape: [1, NSNumber(value: sequenceLength)], dataType: .int32) else {
            throw TextGeneratorError.inputCreationError
        }
        
        for (index, tokenID) in tokens.enumerated() {
            inputIdsArray[[0, NSNumber(value: index)] as [NSNumber]] = NSNumber(value: tokenID)
        }
        
        return inputIdsArray
    }
    
    private func createCausalMaskArray(sequenceLength: Int) throws -> MLMultiArray {
        guard let causalMaskArray = try? MLMultiArray(shape: [1, 1, NSNumber(value: sequenceLength), NSNumber(value: sequenceLength)], dataType: .float32) else {
            throw TextGeneratorError.inputCreationError
        }
        
        for i in 0..<sequenceLength {
            for j in 0..<sequenceLength {
                let maskValue: Float = i >= j ? 0.0 : -Float.infinity
                causalMaskArray[[0, 0, NSNumber(value: i), NSNumber(value: j)] as [NSNumber]] = NSNumber(value: maskValue)
            }
        }
        
        return causalMaskArray
    }
}
