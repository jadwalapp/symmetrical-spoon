//
//  ContentView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainAppView()
            } else {
                AuthView()
            }
        }
    }
}

#Preview {
    ContentView()
}
