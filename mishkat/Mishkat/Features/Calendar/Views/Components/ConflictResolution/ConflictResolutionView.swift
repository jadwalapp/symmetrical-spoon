import SwiftUI
import EventKit

/// View for resolving a scheduling conflict between calendar events
struct ConflictResolutionView: View {
    let conflict: Conflict
    @StateObject private var conflictManager = ConflictManager.shared
    @EnvironmentObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedResolution: Conflict.ConflictResolution?
    @State private var isMovingEvent = false
    @State private var newDate: Date
    
    init(conflict: Conflict) {
        self.conflict = conflict
        _newDate = State(initialValue: conflict.originalEvent.startDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Conflict Visualization Area
                ConflictTimelineView(
                    newEventInfo: conflict.originalEvent,
                    existingEventsInfo: conflict.conflictingEvents,
                    proposedNewDate: $newDate,
                    isMovingEvent: isMovingEvent,
                    selectedResolution: selectedResolution
                )
                .environmentObject(viewModel)
                .frame(minHeight: 150, maxHeight: 250)
                .padding(.horizontal)
                .background(Color(.secondarySystemBackground))
                
                Divider()
                
                // Resolution Options Area
                ScrollView {
                    VStack(spacing: 16) {
                        Text("How would you like to resolve this conflict?")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        VStack(spacing: 12) {
                            // Keep All Option
                            ResolutionOptionView(
                                icon: "calendar.badge.plus",
                                title: "Keep All Events",
                                description: "Keep all events as scheduled despite the conflict",
                                isSelected: selectedResolution == .keepBoth,
                                action: {
                                    withAnimation {
                                        selectedResolution = .keepBoth
                                        isMovingEvent = false
                                    }
                                }
                            )
                            
                            // Reschedule Option
                            ResolutionOptionView(
                                icon: "arrow.right.circle",
                                title: "Reschedule New Event",
                                description: "Move the new event to a different time",
                                isSelected: isMovingEvent,
                                action: {
                                    withAnimation {
                                        isMovingEvent = true
                                        selectedResolution = nil
                                    }
                                }
                            )
                            
                            // Cancel Option
                            ResolutionOptionView(
                                icon: "trash",
                                title: "Cancel New Event",
                                description: "Remove the new event from your calendar",
                                isSelected: selectedResolution == .deleteEvent(conflict.originalEvent),
                                action: {
                                    withAnimation {
                                        selectedResolution = .deleteEvent(conflict.originalEvent)
                                        isMovingEvent = false
                                    }
                                }
                            )
                        }
                        
                        // Date Picker (Compact)
                        if isMovingEvent {
                            DatePicker("New Date and Time", selection: $newDate)
                                .datePickerStyle(.compact)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                    }
                }
                
                // Action Buttons
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                    .padding()
                    
                    Spacer()
                    
                    Button {
                        // Move calculation of final resolution here
                        let finalResolution: Conflict.ConflictResolution?
                        if isMovingEvent {
                            finalResolution = .moveEvent(conflict.originalEvent, newDate)
                        } else {
                            finalResolution = selectedResolution
                        }
                        
                        // Call the async function in a Task
                        if let resolution = finalResolution {
                            Task {
                                await conflictManager.resolveConflict(conflict, with: resolution)
                                // Dismiss happens regardless of success/failure for now
                                // Consider showing an error alert if resolveConflict fails
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Resolve")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .foregroundColor(.white)
                            .background(
                                // Determine if a valid resolution is ready
                                (selectedResolution != nil || isMovingEvent) ?
                                Color.accentColor : Color.gray.opacity(0.5)
                            )
                            .cornerRadius(16)
                    }
                    // Disable button if no resolution selected OR if moving event hasn't been confirmed
                    .disabled(selectedResolution == nil && !isMovingEvent)
                    .padding()
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                 ToolbarItem(placement: .cancellationAction) {
                     Button("Cancel") {
                         dismiss()
                     }
                     .tint(.green)
                 }
            }
        }
    }
} 
