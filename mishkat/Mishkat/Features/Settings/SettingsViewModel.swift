//
//  SettingsViewModel.swift
//  Mishkat
//
//  Created by Human on 02/11/2024.
//

import Foundation

class SettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
}
