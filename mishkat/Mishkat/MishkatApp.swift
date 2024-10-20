//
//  MishkatApp.swift
//  Mishkat
//
//  Created by Human on 19/10/2024.
//

import SwiftUI
import GRPC

@main
struct MishkatApp: App {
    @StateObject private var authViewModel: AuthViewModel
    
    init() {
        let channel = ClientConnection.insecure(group: PlatformSupport.makeEventLoopGroup(loopCount: 1))
            .connect(host: "falak.jadwal.app", port: 80)
        
        let client = Auth_AuthNIOClient(
            channel: channel,
            defaultCallOptions: CallOptions()
        )
        
        let authRepository = AuthRepository(authClient: client)
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authRepository: authRepository))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    print("we got this url 🥳: \(url)")
                }
        }
    }
}
