//
//  TokenInterceptor.swift
//  Mishkat
//
//  Created by Human on 21/10/2024.
//

import Foundation
import GRPC
import NIOCore
import GRPCCore

class TokenInterceptor: GRPC.ClientInterceptor<Any, Any>, @unchecked Sendable {
    func intercept<Request, Response>(
        _ request: Request,
        context: ClientInterceptorContext<Request, Response>,
        next: @escaping (Request, ClientInterceptorContext<Request, Response>) -> EventLoopFuture<Response>
    ) -> EventLoopFuture<Response> {
        let modifiedContext = context
        if let token = KeychainManager.shared.getToken() {
            print("access token: \(token)")
            
            var options = modifiedContext.options
            var headers = options.customMetadata
            headers.add(name: "Authorization", value: "Bearer \(token)")
        }
        return next(request, modifiedContext)
    }
}
