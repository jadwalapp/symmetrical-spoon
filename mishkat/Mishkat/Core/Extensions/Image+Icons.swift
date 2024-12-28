//
//  Image+Icons.swift
//  Mishkat
//
//  Created by Human on 28/12/2024.
//

import SwiftUI

extension Image {
    public init(_ icon: Icons, bundle: Bundle? = nil) {
        self.init(icon.rawValue, bundle: bundle)
    }
}
