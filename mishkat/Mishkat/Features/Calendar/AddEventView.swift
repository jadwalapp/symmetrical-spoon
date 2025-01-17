//
//  AddEventView.swift
//  Mishkat
//
//  Created by Human on 26/11/2024.
//

import SwiftUI
import EventKitUI

struct AddEventView: UIViewControllerRepresentable {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        viewModel.addEvent()
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, EKEventEditViewDelegate {
        var parent: AddEventView

        init(_ parent: AddEventView) {
            self.parent = parent
            super.init()
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(dismissAddEventView),
                name: NSNotification.Name("DismissAddEventView"),
                object: nil
            )
        }
        
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            parent.viewModel.eventEditViewController(controller, didCompleteWith: action)
        }
        
        @objc func dismissAddEventView() {
            parent.isPresented = false
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

#Preview {
    AddEventView(
        isPresented: .constant(true)
    )
    .environmentObject(CalendarViewModel())
}
