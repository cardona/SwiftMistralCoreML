import Testing
@testable import SwiftMistralCoreML
import CoreML

@Suite("Text Generator", .serialized) struct TextGeneratorTests {

    @Test("Default model configuration")
    func textGenerator() async throws {
        let _ = try TextGenerator()
    }


    @Test("Model configuration",
          arguments: [MLComputeUnits.cpuOnly, .cpuAndGPU, .all, .cpuAndNeuralEngine])
    func textGeneratorWithConfiguration(computeUnits: MLComputeUnits) async throws {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = computeUnits
        let _ = try TextGenerator(configuration: configuration)
    }
}
