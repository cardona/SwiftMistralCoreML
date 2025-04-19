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

class ModelActor : @unchecked Sendable {
    private var model: Any?
    private var state: Any?
    private var currentModelType: MistralType?
    private var configuration = MLModelConfiguration()

    init(configuration: MLModelConfiguration) {
        self.configuration = configuration
    }

    func generateNextToken(
        currentInputIds: [Int],
        decodingStrategy: DecodingStrategy,
        modelType: MistralType
    ) throws -> Int {
        try generateTokenInternal(
            currentInputIds: currentInputIds,
            decodingStrategy: decodingStrategy,
            modelType: modelType
        )
    }

    func generateNextTokenAsync(
        currentInputIds: [Int],
        decodingStrategy: DecodingStrategy,
        modelType: MistralType
    ) async throws -> Int {
        try await generateTokenInternalAsync(
            currentInputIds: currentInputIds,
            decodingStrategy: decodingStrategy,
            modelType: modelType
        )
    }

    private func prepareInputs(
        currentInputIds: [Int],
        modelType: MistralType
    ) throws -> (inputIdsArray: MLMultiArray, causalMaskArray: MLMultiArray) {
        try validateAndInitializeModel(modelType: modelType)
        return try createInputArrays(from: currentInputIds)
    }

    private func processOutput(
        prediction: Any,
        decodingStrategy: DecodingStrategy
    ) throws -> Int {
        let logitsArray = try extractLogits(from: prediction)
        return try decodingStrategy.nextToken(logitsArray: logitsArray)
    }

    private func generateTokenInternal(
        currentInputIds: [Int],
        decodingStrategy: DecodingStrategy,
        modelType: MistralType
    ) throws -> Int {
        let (inputIdsArray, causalMaskArray) = try prepareInputs(
            currentInputIds: currentInputIds,
            modelType: modelType
        )

        let prediction = try makePrediction(
            inputIdsArray: inputIdsArray,
            causalMaskArray: causalMaskArray
        )

        return try processOutput(
            prediction: prediction,
            decodingStrategy: decodingStrategy
        )
    }

    private func generateTokenInternalAsync(
        currentInputIds: [Int],
        decodingStrategy: DecodingStrategy,
        modelType: MistralType
    ) async throws -> Int {
        let (inputIdsArray, causalMaskArray) = try prepareInputs(
            currentInputIds: currentInputIds,
            modelType: modelType
        )

        let prediction = try await makePredictionAsync(
            inputIdsArray: inputIdsArray,
            causalMaskArray: causalMaskArray
        )

        return try processOutput(
            prediction: prediction,
            decodingStrategy: decodingStrategy
        )
    }

    private func validateAndInitializeModel(modelType: MistralType) throws {
        if model == nil || currentModelType != modelType {
            try initializeModel(modelType: modelType)
        }
    }

    private func createInputArrays(from currentInputIds: [Int]) throws -> (MLMultiArray, MLMultiArray) {
        let inputIdsArray = try createInputIdsArray(tokens: currentInputIds)
        let causalMaskArray = try createCausalMaskArray(sequenceLength: currentInputIds.count)
        return (inputIdsArray, causalMaskArray)
    }

    private func createModelInput<T>(
        inputIdsArray: MLMultiArray,
        causalMaskArray: MLMultiArray,
        type: T.Type
    ) -> T where T: MLFeatureProvider {
        if type == StatefulMistral7BInstructInt4Input.self {
            return StatefulMistral7BInstructInt4Input(
                inputIds: inputIdsArray,
                causalMask: causalMaskArray
            ) as! T
        } else {
            return StatefulMistral7BInstructFP16Input(
                inputIds: inputIdsArray,
                causalMask: causalMaskArray
            ) as! T
        }
    }

    private func makePrediction(
        inputIdsArray: MLMultiArray,
        causalMaskArray: MLMultiArray
    ) throws -> Any {
        switch model {
        case is StatefulMistral7BInstructInt4:
            let modelInput = createModelInput(
                inputIdsArray: inputIdsArray,
                causalMaskArray: causalMaskArray,
                type: StatefulMistral7BInstructInt4Input.self
            )
            return try predictInt4(modelInput: modelInput)

        case is StatefulMistral7BInstructFP16:
            let modelInput = createModelInput(
                inputIdsArray: inputIdsArray,
                causalMaskArray: causalMaskArray,
                type: StatefulMistral7BInstructFP16Input.self
            )
            return try predictFP16(modelInput: modelInput)

        default:
            throw TextGeneratorError.outputCastingError
        }
    }

    private func makePredictionAsync(
        inputIdsArray: MLMultiArray,
        causalMaskArray: MLMultiArray
    ) async throws -> Any {
        switch model {
        case is StatefulMistral7BInstructInt4:
            let modelInput = createModelInput(
                inputIdsArray: inputIdsArray,
                causalMaskArray: causalMaskArray,
                type: StatefulMistral7BInstructInt4Input.self
            )
            return try await predictInt4Async(modelInput: modelInput)

        case is StatefulMistral7BInstructFP16:
            let modelInput = createModelInput(
                inputIdsArray: inputIdsArray,
                causalMaskArray: causalMaskArray,
                type: StatefulMistral7BInstructFP16Input.self
            )
            return try await predictFP16Async(modelInput: modelInput)

        default:
            throw TextGeneratorError.outputCastingError
        }
    }

    private func predictInt4(modelInput: StatefulMistral7BInstructInt4Input) throws -> Any {
        guard let castedModel = model as? StatefulMistral7BInstructInt4,
              let castedState = state as? StatefulMistral7BInstructInt4State else {
            throw TextGeneratorError.outputCastingError
        }

        return try castedModel.prediction(
            input: modelInput,
            using: castedState
        )
    }

    private func predictInt4Async(modelInput: StatefulMistral7BInstructInt4Input) async throws -> Any {
        guard let castedModel = model as? StatefulMistral7BInstructInt4,
              let castedState = state as? StatefulMistral7BInstructInt4State else {
            throw TextGeneratorError.outputCastingError
        }

        let options = MLPredictionOptions()
        return try await castedModel.prediction(
            input: modelInput,
            using: castedState,
            options: options
        )
    }

    private func predictFP16(modelInput: StatefulMistral7BInstructFP16Input) throws -> Any {
        guard let castedModel = model as? StatefulMistral7BInstructFP16,
              let castedState = state as? StatefulMistral7BInstructFP16State else {
            throw TextGeneratorError.outputCastingError
        }

        return try castedModel.prediction(
            input: modelInput,
            using: castedState
        )
    }

    private func predictFP16Async(modelInput: StatefulMistral7BInstructFP16Input) async throws -> Any {
        guard let castedModel = model as? StatefulMistral7BInstructFP16,
              let castedState = state as? StatefulMistral7BInstructFP16State else {
            throw TextGeneratorError.outputCastingError
        }

        let options = MLPredictionOptions()
        return try await castedModel.prediction(
            input: modelInput,
            using: castedState,
            options: options
        )
    }

    private func extractLogits(from prediction: Any) throws -> MLMultiArray {
        switch prediction {
        case let output as StatefulMistral7BInstructInt4Output:
            return output.logits
        case let output as StatefulMistral7BInstructFP16Output:
            return output.logits
        default:
            throw TextGeneratorError.outputCastingError
        }
    }

    private func initializeModel(modelType: MistralType) throws {
        do {
            switch modelType {
            case .int4:
                let int4Model = try StatefulMistral7BInstructInt4(configuration: configuration)
                self.model = int4Model
                self.state = int4Model.makeState()
            case .fp16:
                let fp16Model = try StatefulMistral7BInstructFP16(configuration: configuration)
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
        guard let inputIdsArray = try? MLMultiArray(
            shape: [1, NSNumber(value: sequenceLength)],
            dataType: .int32
        ) else {
            throw TextGeneratorError.inputCreationError
        }

        for (index, tokenID) in tokens.enumerated() {
            inputIdsArray[[0, NSNumber(value: index)] as [NSNumber]] = NSNumber(value: tokenID)
        }

        return inputIdsArray
    }

    private func createCausalMaskArray(sequenceLength: Int) throws -> MLMultiArray {
        guard let causalMaskArray = try? MLMultiArray(
            shape: [1, 1, NSNumber(value: sequenceLength),
            NSNumber(value: sequenceLength)],
            dataType: .float32
        ) else {
            throw TextGeneratorError.inputCreationError
        }

        for i in 0..<sequenceLength {
            for j in 0..<sequenceLength {
                let maskValue: Float = i >= j ? 0.0 : -Float.infinity
                causalMaskArray[
                    [0, 0, NSNumber(value: i), NSNumber(value: j)] as [NSNumber]
                ] = NSNumber(value: maskValue)
            }
        }

        return causalMaskArray
    }
}
