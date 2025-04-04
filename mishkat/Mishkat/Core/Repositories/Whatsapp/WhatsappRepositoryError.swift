//
//  WhatsappRepositoryError.swift
//  Mishkat
//
//  Created by Human on 29/03/2025.
//

import Foundation

enum WhatsappRepositoryError: LocalizedError {
    case unknown
    case notFound
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "An unknown error occurred"
        case .notFound:
            return "WhatsApp account not found"
        case .timeout:
            return "The operation timed out. Please try again."
        }
    }
}
