//
//  MistralInput.swift
//  SwiftMistralCoreML
//
//  Created by Oscar Cardona on 29/9/24.
//


import Foundation
import CoreML

public enum Role: String {
    case system = "system"
    case user = "user"
    case assistant = "assistant"
}

public struct Message {
    public let role: Role
    public let content: String
    
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

public struct MistralInput {
    public let inputTokens: [Int]
    public let tokenizer: TokenizerParser

    public init(messages: [Message], bpeEncoder: BPEEncoder, tokenizer: TokenizerParser) throws {
        self.tokenizer = tokenizer

        let formattedInputString = MistralInput.formatMessages(messages)
        print("Formatted Input String:")
        print(formattedInputString)

        let tokenizedInput = bpeEncoder.encode(text: formattedInputString)
        print("Input Token IDs:")
        print(tokenizedInput)
        let tokenizedOutput = bpeEncoder.decode(tokenIDs: tokenizedInput)
        print(tokenizedOutput)
        self.inputTokens = tokenizedInput
    }

    static func formatMessages(_ messages: [Message]) -> String {
        var formattedString = ""
        var systemMessage: String? = nil
        var loopMessages = messages

        if messages.first?.role == .system {
            systemMessage = messages.first?.content
            loopMessages = Array(messages.dropFirst())
        }

        if let systemMsg = systemMessage {
            formattedString += "<s>[INST] \(systemMsg) [/INST] "
        }

        for (_, message) in loopMessages.enumerated() {
            switch message.role {
            case .user:
                formattedString += "<s>[INST] user: \(message.content) [/INST] [INST] assistant: "
            case .assistant:
                formattedString += "\(message.content) </s> "
            default:
                fatalError("Only 'system', 'user', and 'assistant' roles are allowed.")
            }
        }

        if let lastMessage = loopMessages.last, lastMessage.role == .user {
            formattedString += "</s> "
        }

        print("Formatted messages into input string:")
        print(formattedString)
        return formattedString
    }

    enum MistralInputError: Error {
        case invalidTokenArraySize
    }
}
