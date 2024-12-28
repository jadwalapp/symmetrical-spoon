//
//  AsyncResponse.swift
//  Mishkat
//
//  Created by Human on 22/12/2024.
//

import SwiftUI

enum AsyncValue<Value>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case failed(Error)
    
    var loadedValue: Value? {
        if case .loaded(let value) = self {
            return value
        }
        return nil
    }
    
    var stateIdentifier: Int {
        switch self {
        case .idle: return 0
        case .loading: return 1
        case .loaded: return 2
        case .failed: return 3
        }
    }
    
    static func == (
        lhs: AsyncValue<Value>,
        rhs: AsyncValue<Value>
    ) -> Bool {
        return lhs.stateIdentifier == rhs.stateIdentifier
    }
}

struct AsyncView<Response, Content: View>: View {
    let response: AsyncValue<Response>
    let mockResponse: Response
    @ViewBuilder let content: (Response) -> Content
    
    var body: some View {
        responseView
    }
    
    @ViewBuilder private var responseView: some View {
        Group {
            switch response {
            case .loaded, .loading, .idle:
                let isLoaded = response.loadedValue != nil
                content(response.loadedValue ?? mockResponse)
                    .redacted(reason: isLoaded ? [] : .placeholder)
                    .allowsHitTesting(isLoaded)
                
            case .failed(let error):
                failureView(error: error)
            }
        }
        .animation(.default, value: response.stateIdentifier)
    }
    
    private func failureView(error: Error) -> some View {
        VStack {
            Text(getBestPossibleTitle(for: error))
                .font(.title2)
                .padding(.bottom, 8)
            Text(getBestPossibleDescription(for: error))
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func getBestPossibleTitle(for error: Error) -> String {
        let nsError = error as NSError
        return nsError.localizedFailureReason ?? "An Error Occurred"
    }
    
    private func getBestPossibleDescription(for error: Error) -> String {
        let nsError = error as NSError
        return nsError.localizedRecoverySuggestion ?? error.localizedDescription
    }
}

extension AsyncView where Response: Mockable {
    init(response: AsyncValue<Response>, @ViewBuilder content: @escaping (Response) -> Content) {
        self.response = response
        self.mockResponse = Response.makeMock()
        self.content = content
    }
}

#Preview {
    AsyncView(
        response: .loading,
        mockResponse: Profile_V1_GetProfileResponse.makeMock()
    ) { _ in
        Text("Preview Content")
    }
    
    AsyncView(
        response: .failed(ProfileRepositoryError.unknown),
        mockResponse: Profile_V1_GetProfileResponse.makeMock()
    ) { _ in
        Text("Preview Content")
    }
}
