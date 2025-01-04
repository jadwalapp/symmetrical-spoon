//
//  DependencyContainer.swift
//  Mishkat
//
//  Created by Human on 21/10/2024.
//

import Foundation
import Connect

class DependencyContainer {
    static let shared = DependencyContainer()
    
    private init() {}
    
    lazy var client = ProtocolClient(
        httpClient: URLSessionHTTPClient(),
        config: ProtocolClientConfig(
            host: "https://falak.jadwal.app",
//            host: "http://localhost:50064",
            networkProtocol: .connect,
            interceptors: [InterceptorFactory { AuthInterceptor(config: $0) }]
        )
    )
    
    lazy private var authClient: Auth_V1_AuthServiceClient = { return Auth_V1_AuthServiceClient(client: client) }()
    lazy var authRepository: AuthRepository = { return AuthRepository(authClient: authClient) }()
    
    lazy private var profileClient: Profile_V1_ProfileServiceClient = { return Profile_V1_ProfileServiceClient(client: client) }()
    lazy var profileRepository: ProfileRepository = { return ProfileRepository(profileClient: profileClient) }()
    
    lazy private var calendarClient: Calendar_V1_CalendarServiceClient = { return Calendar_V1_CalendarServiceClient(client: client) }()
    lazy var calendarRepository: CalendarRepository = { return CalendarRepository(calendarClient: calendarClient) }()
}
