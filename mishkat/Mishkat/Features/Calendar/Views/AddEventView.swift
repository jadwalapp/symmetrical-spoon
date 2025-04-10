//
//  AddEventView.swift
//  Mishkat
//
//  Created by Human on 26/11/2024.
//

import SwiftUI
import EventKitUI

/// View for adding or editing an event in the calendar.
struct AddEventView: UIViewControllerRepresentable {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Binding var isPresented: Bool
    var event: EKEvent? = nil

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        if let existingEvent = event {
            let controller = EKEventEditViewController()
            controller.event = existingEvent
            controller.eventStore = viewModel.eventStore
            controller.editViewDelegate = context.coordinator
            return controller
        }
        return viewModel.addEvent()
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
            parent.isPresented = false
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
    AddEventView(isPresented: .constant(true))
        .environmentObject(CalendarViewModel())
}
