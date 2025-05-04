//
//  PresenterResolverWrapper.swift
//  Mishkat
//
//  Created by Human on 04/05/2025.
//

import SwiftUI

struct PresenterResolverWrapper<Content: View>: View {
    @ViewBuilder let content: (UIViewController) -> Content
    @State private var resolvedController: UIViewController?
    
    var body: some View {
        ZStack {
            if let controller = resolvedController {
                content(controller)
            }
            
            ViewControllerResolver { controller in
                resolvedController = controller
            }
            .frame(width: 0, height: 0)
            
        }
    }
}

struct ViewControllerResolver: UIViewControllerRepresentable {
    var onResolve: (UIViewController) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            onResolve(controller)
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
