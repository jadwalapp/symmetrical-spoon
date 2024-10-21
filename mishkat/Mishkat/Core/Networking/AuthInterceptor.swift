//
//  TokenInterceptor.swift
//  Mishkat
//
//  Created by Human on 21/10/2024.
//

import Connect

final class AuthInterceptor: UnaryInterceptor {
    init(config: ProtocolClientConfig) { }
    
    let unauthenticatedRequests: [String] = [
        "/auth.v1.AuthService/InitiateEmail",
        "/auth.v1.AuthService/CompleteEmail",
        "/auth.v1.AuthService/UseGoogle",
    ]
    
    @Sendable
    func handleUnaryRequest<Message: ProtobufMessage>(
        _ request: HTTPRequest<Message>,
        proceed: @escaping @Sendable (Result<HTTPRequest<Message>, ConnectError>) -> Void)
    {
        let reqPath = request.url.path(percentEncoded: false)
        if unauthenticatedRequests.contains(where: { $0 == reqPath}) {
            proceed(.success(request))
            return
        }
        
        if let token = KeychainManager.shared.getToken() {
            var headers = request.headers
            headers["Authorization"] = ["Bearer \(token)"]
            
            proceed(.success(HTTPRequest(
                url: request.url,
                headers: headers,
                message: request.message,
                method: request.method,
                trailers: request.trailers,
                idempotencyLevel: request.idempotencyLevel
            )))
        } else {
            proceed(.failure(ConnectError(
                code: .unknown, message: "auth token fetch failed",
                exception: nil, details: [], metadata: [:]
            )))
        }
    }
}
