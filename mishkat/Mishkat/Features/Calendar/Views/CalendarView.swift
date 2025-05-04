//
//  CalendarView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI
import EventKit
import PostHog

struct CalendarView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @StateObject private var conflictManager = ConflictManager.shared
    @State private var showingAddEventSheet = false
    @State private var showingCalendarsSheet = false
    @State private var isMonthView = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                EnhancedCalendarView(isMonthView: $isMonthView)
                    .blur(radius: viewModel.authorizationStatus != .authorized ? 10 : 0)
                    .refreshable {
                        let generator = UINotificationFeedbackGenerator()
                        generator.prepare()
                        
                        // Show loading state
                        viewModel.isLoading = true
                        
                        await Task.sleep(500_000_000) // 0.5 second visual delay
                        viewModel.refreshAllEvents()
                        
                        generator.notificationOccurred(.success)
                    }
                
                if viewModel.authorizationStatus != .authorized {
                    AccessRequestCard(status: viewModel.authorizationStatus,
                                   requestAccess: viewModel.requestAccess,
                                   openSettings: viewModel.openSettings)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle(isMonthView ? "Calendar" : viewModel.selectedDate.formatted(.dateTime.month().year()))
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isMonthView {
                        Button(action: {
                            withAnimation {
                                isMonthView = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Calendar")
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            PostHogSDK.shared.capture("today_toolbar_item_clicked")
                            viewModel.selectedDate = Date()
                            if !isMonthView {
                                viewModel.fetchDailyEvents(for: Date())
                            }
                        } label: {
                            Text("Today")
                                .foregroundStyle(.green)
                        }
                        
                        Button {
                            PostHogSDK.shared.capture("calendars_toolbar_item_clicked")
                            showingCalendarsSheet.toggle()
                        } label: {
                            Image(systemName: "calendar")
                                .foregroundStyle(.primary)
                        }
                        
                        Button {
                            PostHogSDK.shared.capture("scheduled_conflicts_toolbar_item_clicked")
                            conflictManager.showConflictsView = true
                        } label: {
                            let unresolvedCount = conflictManager.conflicts.filter { !$0.resolved }.count
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(unresolvedCount > 0 ? .orange : .gray.opacity(0.5))
                                
                                if unresolvedCount > 0 {
                                    Text("\(unresolvedCount)")
                                        .font(.system(size: 10))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 16, height: 16)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                        
                        Button {
                            PostHogSDK.shared.capture("add_event_toolbar_item_clicked")
                            showingAddEventSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddEventSheet) {
                AddEventView(isPresented: $showingAddEventSheet)
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showingCalendarsSheet) {
                CalendarsListView()
            }
            .sheet(isPresented: $conflictManager.showConflictsView) {
                ConflictsView()
            }
        }
    }
}

#Preview {
    CalendarView()
}
