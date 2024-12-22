//
//  SettingsProfileTile.swift
//  Mishkat
//
//  Created by Human on 22/12/2024.
//

import SwiftUI

struct SettingsProfileTile: View {
    private let name: String
    private let email: String
    
    init(name: String, email: String) {
        self.name = name
        self.email = email
    }
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: 60)
                .padding(.trailing, 16)
            VStack(alignment: .leading) {
                Text("Hello \(name)!")
                    .font(.headline)
                Text(email)
                    .font(.subheadline)
            }
            Spacer()
        }
    }
}

#Preview {
    List {
        Section {
            SettingsProfileTile(
                name: "Yazeed",
                email: "yazeedfady@gmail.com"
            )
        }
    }
}
