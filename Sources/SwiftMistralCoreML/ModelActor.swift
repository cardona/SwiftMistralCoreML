//
//  ModelActor.swift
//  SwiftMistralCoreML
//
//  Created by Oscar Cardona on 12/10/24.
//


import Foundation
import CoreML

public enum MistralType: Sendable {
    case int4
    case fp16
}

actor ModelActor {
    private var model: Any?
    private var state: Any?
    private var currentModelType: MistralType?
    
    func generateNextToken(currentInputIds: [Int], decodingStrategy: DecodingStrategy, modelType: MistralType) throws -> Int {
        if model == nil || currentModelType != modelType {
            try initializeModel(modelType: modelType)
        }
        
        let inputIdsArray = try createInputIdsArray(tokens: currentInputIds)
        let causalMaskArray = try createCausalMaskArray(sequenceLength: currentInputIds.count)
        
        let prediction: Any
        do {
            switch model {
            case is StatefulMistral7BInstructInt4:
                let modelInput = StatefulMistral7BInstructInt4Input(inputIds: inputIdsArray, causalMask: causalMaskArray)
                guard let castedModel = model as? StatefulMistral7BInstructInt4, let castedState = state as? StatefulMistral7BInstructInt4State else {
                    throw TextGeneratorError.outputCastingError
                }
                prediction = try castedModel.prediction(input: modelInput, using: castedState)
            case is StatefulMistral7BInstructFP16:
                let modelInput = StatefulMistral7BInstructFP16Input(inputIds: inputIdsArray, causalMask: causalMaskArray)
                guard let castedModel = model as? StatefulMistral7BInstructFP16, let castedState = state as? StatefulMistral7BInstructFP16State else {
                    throw TextGeneratorError.outputCastingError
                }
                prediction = try castedModel.prediction(input: modelInput, using: castedState)
            default:
                throw TextGeneratorError.outputCastingError
            }
        } catch {
            throw TextGeneratorError.outputCastingError
        }
        
        let logitsArray: MLMultiArray
        switch prediction {
        case let output as StatefulMistral7BInstructInt4Output:
            logitsArray = output.logits
        case let output as StatefulMistral7BInstructFP16Output:
            logitsArray = output.logits
        default:
            throw TextGeneratorError.outputCastingError
        }
        
        return try decodingStrategy.nextToken(logitsArray: logitsArray)
    }
    
    private func initializeModel(modelType: MistralType) throws {
        do {
            switch modelType {
            case .int4:
                let int4Model = try StatefulMistral7BInstructInt4(configuration: MLModelConfiguration())
                self.model = int4Model
                self.state = int4Model.makeState()
            case .fp16:
                let fp16Model = try StatefulMistral7BInstructFP16(configuration: MLModelConfiguration())
                self.model = fp16Model
                self.state = fp16Model.makeState()
            }
            self.currentModelType = modelType
        } catch {
            throw TextGeneratorError.missingMistral7B
        }
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
