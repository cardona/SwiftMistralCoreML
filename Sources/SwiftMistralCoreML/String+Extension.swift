//
//  String+Extension.swift
//  SwiftMistralCoreML
//
//  Created by Oscar Cardona on 8/10/24.
//

import Foundation

public extension String {
    func cleanGeneratedText() -> String {
        var cleanText = self
        
        cleanText = cleanText.replacingOccurrences(of: "<0x0A>", with: "\n")
        cleanText = cleanText.replacingOccurrences(of: "<0x09>", with: "\t")
        cleanText = cleanText.replacingOccurrences(of: "<0x20>", with: " ")
        cleanText = cleanText.replacingOccurrences(of: "<0x0D>", with: "\r")
        
        let tokensToRemove = ["[INST]", "[/INST]", "<s>", "</s>", "Assistant:", "User:", "<<SYS>>", "<</SYS>>", "<b>", "</b>", "<i>", "</i>"]
        for token in tokensToRemove {
            cleanText = cleanText.replacingOccurrences(of: token, with: "")
        }

        cleanText = cleanText.replacingOccurrences(of: "▁", with: " ")

        return cleanText
    }
}
