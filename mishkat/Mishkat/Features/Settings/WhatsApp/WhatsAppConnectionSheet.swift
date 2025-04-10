import SwiftUI

struct WhatsAppConnectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WhatsAppViewModel
    
    init(whatsappRepository: WhatsappRepository) {
        _viewModel = StateObject(wrappedValue: WhatsAppViewModel(whatsappRepository: whatsappRepository))
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 32) {
                        switch viewModel.connectionState {
                        case .initial:
                            WhatsAppInitialView(phoneNumber: $viewModel.phoneNumber)
                        case .connecting(let pairingCode):
                            WhatsAppConnectingView(
                                pairingCode: pairingCode,
                                isLoading: viewModel.isLoading,
                                canRefreshCode: viewModel.canRefreshCode,
                                remainingCooldownTime: viewModel.remainingCooldownTime,
                                onRefresh: { viewModel.refreshPairingCode() },
                                onCopy: { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                            )
                        case .connected:
                            WhatsAppSuccessView(onDismiss: { dismiss() })
                        case .failed(let error):
                            WhatsAppErrorView(
                                error: error,
                                isLoading: viewModel.isLoading,
                                onRetry: { viewModel.reset() }
                            )
                        case .initializing:
                            if let existingCode = viewModel.existingPairingCode {
                                VStack {
                                    WhatsAppConnectingView(
                                        pairingCode: existingCode,
                                        isLoading: viewModel.isLoading,
                                        canRefreshCode: viewModel.canRefreshCode,
                                        remainingCooldownTime: viewModel.remainingCooldownTime,
                                        onRefresh: { viewModel.refreshPairingCode() },
                                        onCopy: { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                                    )
                                    
                                    Button {
                                        viewModel.forceReconnect()
                                    } label: {
                                        Label(
                                            "Force Reconnect",
                                            systemImage: "arrow.triangle.2.circlepath"
                                        )
                                        .foregroundStyle(.orange)
                                    }
                                    .buttonStyle(PressableButtonStyle())
                                    .padding(.top, -16)
                                }
                            } else {
                                WhatsAppConnectingView(
                                    pairingCode: "",
                                    isLoading: viewModel.isLoading,
                                    canRefreshCode: viewModel.canRefreshCode,
                                    remainingCooldownTime: viewModel.remainingCooldownTime,
                                    onRefresh: { viewModel.refreshPairingCode() },
                                    onCopy: { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                                )
                            }
                        }
                    }
                    .padding(24)
                }
                
                if case .initial = viewModel.connectionState {
                    VStack(spacing: 0) {
                        Divider()
                        
                        OButton(
                            icon: .brandWhatsapp,
                            label: "Connect WhatsApp",
                            isLoading: viewModel.isLoading,
                            isDisabled: !viewModel.isValidPhoneNumber || viewModel.isLoading
                        ) {
                            viewModel.connectWhatsapp()
                        }
                        .padding()
                    }
                    .background(.background)
                }
            }
            .navigationTitle(headerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isLoading)
    }
    
    private var headerTitle: String {
        switch viewModel.connectionState {
        case .initial:
            return "Connect WhatsApp"
        case .connecting:
            return "Enter Code"
        case .connected:
            return "Success"
        case .failed:
            return "Connection Failed"
        case .initializing:
            return "Complete Setup"
        }
    }
} 