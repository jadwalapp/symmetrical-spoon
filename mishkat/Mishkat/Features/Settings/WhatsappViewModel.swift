import SwiftUI

class WhatsappViewModel: ObservableObject {
    enum ConnectionState {
        case initial
        case connecting(pairingCode: String)
        case connected
        case failed(Error)
    }
    
    @Published private(set) var connectionState: ConnectionState = .initial
    @Published var showWhatsappSheet = false
    @Published var phoneNumber = ""
    
    private let whatsappRepository: WhatsappRepository
    private var pollingTimer: Timer?
    
    init(whatsappRepository: WhatsappRepository) {
        self.whatsappRepository = whatsappRepository
    }
    
    func reset() {
        phoneNumber = ""
        connectionState = .initial
    }
    
    func connectWhatsapp() {
        guard !phoneNumber.isEmpty else { return }
        
        Task {
            do {
                let response = try await whatsappRepository.connectWhatsappAccount(mobile: phoneNumber)
                await MainActor.run {
                    self.connectionState = .connecting(pairingCode: response.pairingCode)
                    self.startPolling()
                }
            } catch {
                await MainActor.run {
                    self.connectionState = .failed(error)
                }
            }
        }
    }
    
    private func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.checkConnectionStatus()
        }
    }
    
    private func checkConnectionStatus() {
        Task {
            do {
                let response = try await whatsappRepository.getWhatsappAccount()
                await MainActor.run {
                    if response.isReady {
                        self.connectionState = .connected
                        self.pollingTimer?.invalidate()
                        self.pollingTimer = nil
                    }
                }
            } catch WhatsappRepositoryError.notFound {
                // This is expected when account is not connected yet, keep polling
                return
            } catch {
                await MainActor.run {
                    self.connectionState = .failed(error)
                    self.pollingTimer?.invalidate()
                    self.pollingTimer = nil
                }
            }
        }
    }
    
    func disconnect() {
        Task {
            do {
                _ = try await whatsappRepository.disconnectWhatsappAccount()
                await MainActor.run {
                    self.connectionState = .initial
                }
            } catch {
                await MainActor.run {
                    self.connectionState = .failed(error)
                }
            }
        }
    }
    
    deinit {
        pollingTimer?.invalidate()
    }
} 
