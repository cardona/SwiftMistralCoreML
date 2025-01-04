//
//  StatefulMistral7BInstructInt4.swift
//  SwiftMistralCoreML


import CoreML


/// Model Prediction Input Type
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
public class StatefulMistral7BInstructInt4Input : MLFeatureProvider,  @unchecked Sendable {

    /// inputIds as 1 by 1 matrix of 32-bit integers
    public var inputIds: MLMultiArray

    /// causalMask as 1 × 1 × 1 × 1 4-dimensional array of 16-bit floats
    public var causalMask: MLMultiArray

    public var featureNames: Set<String> { ["inputIds", "causalMask"] }

    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "inputIds" {
            return MLFeatureValue(multiArray: inputIds)
        }
        if featureName == "causalMask" {
            return MLFeatureValue(multiArray: causalMask)
        }
        return nil
    }

    public init(inputIds: MLMultiArray, causalMask: MLMultiArray) {
        self.inputIds = inputIds
        self.causalMask = causalMask
    }

    #if (os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    #endif
    public convenience init(inputIds: MLShapedArray<Int32>, causalMask: MLShapedArray<Float16>) {
        self.init(inputIds: MLMultiArray(inputIds), causalMask: MLMultiArray(causalMask))
    }
}


/// Model Prediction Output Type
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
public class StatefulMistral7BInstructInt4Output : MLFeatureProvider, @unchecked Sendable  {

    /// Source provided by CoreML
    private let provider : MLFeatureProvider

    /// logits as multidimensional array of 16-bit floats
    public var logits: MLMultiArray {
        provider.featureValue(for: "logits")!.multiArrayValue!
    }

    /// logits as multidimensional array of 16-bit floats
    #if (os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    #endif
    public var logitsShapedArray: MLShapedArray<Float16> {
        MLShapedArray<Float16>(logits)
    }

    public var featureNames: Set<String> {
        provider.featureNames
    }

    public func featureValue(for featureName: String) -> MLFeatureValue? {
        provider.featureValue(for: featureName)
    }

    public init(logits: MLMultiArray) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["logits" : MLFeatureValue(multiArray: logits)])
    }

    public init(features: MLFeatureProvider) {
        self.provider = features
    }
}

/// Model Prediction State Type
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
public final class StatefulMistral7BInstructInt4State : @unchecked Sendable {
    public enum Name: String, CaseIterable {
        case keyCache = "keyCache"
        case valueCache = "valueCache"
    }

    let handle: MLState

    init(handle: MLState) {
        self.handle = handle
    }

    public func withMultiArray<R>(for stateName: Name, _ body: (MLMultiArray) throws -> R) rethrows -> R {
        try handle.withMultiArray(for: stateName.rawValue, body)
    }
}

/// Class for model loading and prediction
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
public class StatefulMistral7BInstructInt4 : @unchecked Sendable {
    public let model: MLModel

    /// URL of model assuming it was installed in the same bundle as this class
    class var urlOfModelInThisBundle : URL {
        let bundle = Bundle.main
        return bundle.url(forResource: "StatefulMistral7BInstructInt4", withExtension:"mlmodelc")!
    }

    /**
        Construct StatefulMistral7BInstructInt4 instance with an existing MLModel object.

        Usually the application does not use this initializer unless it makes a subclass of StatefulMistral7BInstructInt4.
        Such application may want to use `MLModel(contentsOfURL:configuration:)` and `StatefulMistral7BInstructInt4.urlOfModelInThisBundle` to create a MLModel object to pass-in.

        - parameters:
          - model: MLModel object
    */
    init(model: MLModel) {
        self.model = model
    }

    /**
        Construct a model with configuration

        - parameters:
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    public convenience init(configuration: MLModelConfiguration = MLModelConfiguration()) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct StatefulMistral7BInstructInt4 instance with explicit path to mlmodelc file
        - parameters:
           - modelURL: the file url of the model

        - throws: an NSError object that describes the problem
    */
    public convenience init(contentsOf modelURL: URL) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }

    /**
        Construct a model with URL of the .mlmodelc directory and configuration

        - parameters:
           - modelURL: the file url of the model
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    public convenience init(contentsOf modelURL: URL, configuration: MLModelConfiguration) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }

    /**
        Construct StatefulMistral7BInstructInt4 instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    public class func load(configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<StatefulMistral7BInstructInt4, Error>) -> Void) {
        load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration, completionHandler: handler)
    }

    /**
        Construct StatefulMistral7BInstructInt4 instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
    */
    public class func load(configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> StatefulMistral7BInstructInt4 {
        try await load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct StatefulMistral7BInstructInt4 instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    public class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<StatefulMistral7BInstructInt4, Error>) -> Void) {
        MLModel.load(contentsOf: modelURL, configuration: configuration) { result in
            switch result {
            case .failure(let error):
                handler(.failure(error))
            case .success(let model):
                handler(.success(StatefulMistral7BInstructInt4(model: model)))
            }
        }
    }

    /**
        Construct StatefulMistral7BInstructInt4 instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
    */
    public class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> StatefulMistral7BInstructInt4 {
        let model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        return StatefulMistral7BInstructInt4(model: model)
    }

    /**
        Make a new state.

        Core ML framework will allocate the state buffers declared in the model.

        The allocated state buffers are initialized to zeros. To initialize with different values, use `.withMultiArray(for:)` to get the mutable `MLMultiArray`-view to the state buffer.

        ```swift
        let state = model.makeState()
        state.withMultiArray(for: .keyCache) { stateMultiArray in
            stateMultiArray[0] = 0.42
        }
        ```
    */
    public func makeState() -> StatefulMistral7BInstructInt4State {
        StatefulMistral7BInstructInt4State(handle: model.makeState())
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as StatefulMistral7BInstructInt4Input
           - state: the state that the prediction will use and update.

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as StatefulMistral7BInstructInt4Output
    */
    public func prediction(input: StatefulMistral7BInstructInt4Input, using state: StatefulMistral7BInstructInt4State) throws -> StatefulMistral7BInstructInt4Output {
        try prediction(input: input, using: state, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as StatefulMistral7BInstructInt4Input
           - state: the state that the prediction will use and update.
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as StatefulMistral7BInstructInt4Output
    */
    public func prediction(input: StatefulMistral7BInstructInt4Input, using state: StatefulMistral7BInstructInt4State, options: MLPredictionOptions) throws -> StatefulMistral7BInstructInt4Output {
        let outFeatures = try model.prediction(from: input, using: state.handle, options: options)
        return StatefulMistral7BInstructInt4Output(features: outFeatures)
    }

    /**
        Make an asynchronous prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as StatefulMistral7BInstructInt4Input
           - state: the state that the prediction will use and update.
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as StatefulMistral7BInstructInt4Output
    */
    public func prediction(input: StatefulMistral7BInstructInt4Input, using state: StatefulMistral7BInstructInt4State, options: MLPredictionOptions = MLPredictionOptions()) async throws -> StatefulMistral7BInstructInt4Output {
        let outFeatures = try await model.prediction(from: input, using: state.handle, options: options)
        return StatefulMistral7BInstructInt4Output(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface

        It uses the default function if the model has multiple functions.

        - parameters:
            - inputIds: 1 by 1 matrix of 32-bit integers
            - causalMask: 1 × 1 × 1 × 1 4-dimensional array of 16-bit floats
            - state: the state that the prediction will use and update.

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as StatefulMistral7BInstructInt4Output
    */
    public func prediction(inputIds: MLMultiArray, causalMask: MLMultiArray, using state: StatefulMistral7BInstructInt4State) throws -> StatefulMistral7BInstructInt4Output {
        let input_ = StatefulMistral7BInstructInt4Input(inputIds: inputIds, causalMask: causalMask)
        return try prediction(input: input_, using: state)
    }

    /**
        Make a prediction using the convenience interface

        It uses the default function if the model has multiple functions.

        - parameters:
            - inputIds: 1 by 1 matrix of 32-bit integers
            - causalMask: 1 × 1 × 1 × 1 4-dimensional array of 16-bit floats
            - state: the state that the prediction will use and update.

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as StatefulMistral7BInstructInt4Output
    */

    #if (os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    #endif
    public func prediction(inputIds: MLShapedArray<Int32>, causalMask: MLShapedArray<Float16>, using state: StatefulMistral7BInstructInt4State) throws -> StatefulMistral7BInstructInt4Output {
        let input_ = StatefulMistral7BInstructInt4Input(inputIds: inputIds, causalMask: causalMask)
        return try prediction(input: input_, using: state)
    }
}
