import SwiftUI

final class WhatsappViewModel: ObservableObject {
    enum ConnectionState: Equatable {
        case initial
        case initializing
        case connecting(pairingCode: String)
        case connected
        case failed(Error)
        
        static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.initial, .initial),
                (.initializing, .initializing),
                (.connected, .connected):
                return true
            case let (.connecting(code1), .connecting(code2)):
                return code1 == code2
            case let (.failed(error1), .failed(error2)):
                return error1.localizedDescription == error2.localizedDescription
            default:
                return false
            }
        }
    }
    
    @Published private(set) var connectionState: ConnectionState = .initial
    @Published private(set) var isLoading = false
    @Published private(set) var existingPairingCode: String?
    @Published private(set) var lastRefreshTime: Date?
    @Published var phoneNumber = "" {
        didSet {
            let cleanedInput = phoneNumber.filter { $0.isNumber || $0 == "+" }
            if cleanedInput != phoneNumber {
                phoneNumber = cleanedInput
                return
            }
            
            if phoneNumber.hasPrefix("+") {
                if phoneNumber == "+" { return }
                phoneNumber = String(phoneNumber.dropFirst())
            }
        }
    }
    
    var formattedPhoneNumber: String {
        phoneNumber.isEmpty ? "" : "+" + phoneNumber
    }
    
    var isValidPhoneNumber: Bool {
        let numberOnly = phoneNumber.filter { $0.isNumber }
        return numberOnly.count >= 8 && numberOnly.count <= 15
    }
    
    var canRefreshCode: Bool {
        guard let lastRefresh = lastRefreshTime else { return true }
        return Date().timeIntervalSince(lastRefresh) >= 30
    }
    
    var remainingCooldownTime: Int {
        guard let lastRefresh = lastRefreshTime else { return 0 }
        return max(30 - Int(Date().timeIntervalSince(lastRefresh)), 0)
    }
    
    private let whatsappRepository: WhatsappRepository
    private var pollingTimer: Timer?
    private var pollAttempts = 0
    private let maxPollAttempts = 60
    
    init(whatsappRepository: WhatsappRepository) {
        self.whatsappRepository = whatsappRepository
        checkExistingSession()
    }
    
    func reset() {
        phoneNumber = ""
        connectionState = .initial
        isLoading = false
        pollingTimer?.invalidate()
        pollingTimer = nil
        pollAttempts = 0
    }
    
    func connectWhatsapp() {
        guard isValidPhoneNumber else { return }
        
        isLoading = true
        Task {
            do {
                _ = try? await whatsappRepository.disconnectWhatsappAccount()
                let response = try await whatsappRepository.connectWhatsappAccount(mobile: phoneNumber)
                await MainActor.run {
                    self.connectionState = .connecting(pairingCode: response.pairingCode)
                    self.startPolling()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.connectionState = .failed(error)
                    self.isLoading = false
                }
            }
        }
    }
    
    func forceReconnect() {
        isLoading = true
        Task {
            do {
                _ = try await whatsappRepository.disconnectWhatsappAccount()
                let response = try await whatsappRepository.connectWhatsappAccount(mobile: phoneNumber)
                await MainActor.run {
                    self.connectionState = .connecting(pairingCode: response.pairingCode)
                    self.startPolling()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.connectionState = .failed(error)
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshPairingCode() {
        guard canRefreshCode else { return }
        
        isLoading = true
        lastRefreshTime = Date()
        
        Task {
            do {
                _ = try await whatsappRepository.disconnectWhatsappAccount()
                let response = try await whatsappRepository.connectWhatsappAccount(mobile: phoneNumber)
                await MainActor.run {
                    self.connectionState = .connecting(pairingCode: response.pairingCode)
                    self.startPolling()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.connectionState = .failed(error)
                    self.isLoading = false
                }
            }
        }
    }
    
    func checkExistingSession() {
        Task {
            do {
                let response = try await whatsappRepository.getWhatsappAccount()
                await MainActor.run {
                    if response.isReady {
                        self.connectionState = .connected
                    } else if response.status == "WAITING_FOR_PAIRING" {
                        self.existingPairingCode = response.pairingCode
                        self.connectionState = .initializing
                    } else {
                        self.connectionState = .initial
                    }
                }
            } catch WhatsappRepositoryError.notFound {
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
    
    private func startPolling() {
        pollAttempts = 0
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.checkConnectionStatus()
        }
    }
    
    private func checkConnectionStatus() {
        pollAttempts += 1
        if pollAttempts >= maxPollAttempts {
            Task { @MainActor in
                connectionState = .failed(WhatsappRepositoryError.timeout)
                pollingTimer?.invalidate()
                pollingTimer = nil
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            return
        }
        
        Task {
            do {
                let response = try await whatsappRepository.getWhatsappAccount()
                await MainActor.run {
                    if response.isReady {
                        self.connectionState = .connected
                        self.pollingTimer?.invalidate()
                        self.pollingTimer = nil
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
            } catch WhatsappRepositoryError.notFound {
                return
            } catch {
                await MainActor.run {
                    self.connectionState = .failed(error)
                    self.pollingTimer?.invalidate()
                    self.pollingTimer = nil
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    
    deinit {
        pollingTimer?.invalidate()
    }
} 
