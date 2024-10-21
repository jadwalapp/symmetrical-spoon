//
//  DependencyContainer.swift
//  Mishkat
//
//  Created by Human on 21/10/2024.
//

import Foundation
import GRPC

class DependencyContainer {
    static let shared = DependencyContainer()
    
    private init() {}
    
    lazy var grpcChannel: ClientConnection = {
        let channel = ClientConnection.secure(
            group: PlatformSupport.makeEventLoopGroup(loopCount: 1)
        ).connect(host: "falak.jadwal.app", port: 443)
        return channel
    }()
    
    lazy var authClient: Auth_AuthNIOClient = {
        return Auth_AuthNIOClient(
            channel: grpcChannel
        )
    }()
    
    lazy var authRepository: AuthRepository = {
        return AuthRepository(authClient: authClient)
    }()
}
