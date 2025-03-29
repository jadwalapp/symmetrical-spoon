import SwiftUI

class WhatsappViewModel: ObservableObject {
    enum ConnectionState {
        case initial
        case initializing
        case connecting(pairingCode: String)
        case connected
        case failed(Error)
        
        var isConnecting: Bool {
            if case .connecting = self {
                return true
            }
            return false
        }
        
        var needsUserIntervention: Bool {
            if case .initializing = self {
                return true
            }
            return false
        }
    }
    
    @Published private(set) var connectionState: ConnectionState = .initial
    @Published var showWhatsappSheet = false
    @Published private(set) var existingPairingCode: String?
    @Published var phoneNumber = "" {
        didSet {
            // First, clean the input to only allow numbers and plus sign
            let cleanedInput = phoneNumber.filter { $0.isNumber || $0 == "+" }
            if cleanedInput != phoneNumber {
                phoneNumber = cleanedInput
                return
            }
            
            // Handle the plus prefix
            if phoneNumber.hasPrefix("+") {
                // If it's just a plus, keep it
                if phoneNumber == "+" {
                    return
                }
                // Otherwise, store without the plus
                phoneNumber = String(phoneNumber.dropFirst())
                return
            }
        }
    }
    
    @Published private(set) var lastRefreshTime: Date?
    
    var formattedPhoneNumber: String {
        guard !phoneNumber.isEmpty else { return "" }
        return "+" + phoneNumber
    }
    
    var isValidPhoneNumber: Bool {
        // International phone numbers are typically between 8 and 15 digits
        // Country code (1-3 digits) + local number (7-12 digits)
        let numberOnly = phoneNumber.filter { $0.isNumber }
        return numberOnly.count >= 8 && numberOnly.count <= 15
    }
    
    @Published private(set) var isLoading = false {
        didSet {
            if isLoading {
                // Start a timeout timer to prevent infinite loading
                startLoadingTimeout()
                // Provide haptic feedback
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            } else {
                loadingTimeoutTimer?.invalidate()
                loadingTimeoutTimer = nil
            }
        }
    }
    
    private let whatsappRepository: WhatsappRepository
    private var pollingTimer: Timer?
    private var loadingTimeoutTimer: Timer?
    private var pollAttempts = 0
    private let maxPollAttempts = 60 // 3 minutes (3s * 60)
    
    var canRefreshCode: Bool {
        guard let lastRefresh = lastRefreshTime else { return true }
        return Date().timeIntervalSince(lastRefresh) >= 30 // 30 seconds cooldown
    }
    
    var remainingCooldownTime: Int {
        guard let lastRefresh = lastRefreshTime else { return 0 }
        let elapsed = Date().timeIntervalSince(lastRefresh)
        let remaining = max(30 - Int(elapsed), 0)
        return remaining
    }
    
    init(whatsappRepository: WhatsappRepository) {
        self.whatsappRepository = whatsappRepository
    }
    
    func reset() {
        phoneNumber = ""
        connectionState = .initial
        isLoading = false
        pollingTimer?.invalidate()
        pollingTimer = nil
        loadingTimeoutTimer?.invalidate()
        loadingTimeoutTimer = nil
        pollAttempts = 0
    }
    
    private func startLoadingTimeout() {
        loadingTimeoutTimer?.invalidate()
        loadingTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.handleLoadingTimeout()
        }
    }
    
    private func handleLoadingTimeout() {
        Task { @MainActor in
            isLoading = false
            connectionState = .failed(WhatsappRepositoryError.timeout)
            // Provide error feedback
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    func connectWhatsapp() {
        guard isValidPhoneNumber else { return }
        
        isLoading = true
        Task {
            do {
                // First, try to disconnect any existing session
                _ = try? await whatsappRepository.disconnectWhatsappAccount()
                
                // Then create a new connection
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
                // First disconnect
                _ = try await whatsappRepository.disconnectWhatsappAccount()
                
                // Then create a new connection with the existing phone number
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
                // First disconnect the current session
                _ = try await whatsappRepository.disconnectWhatsappAccount()
                
                // Then create a new connection
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
                // Provide error feedback
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
                        // Provide success feedback
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
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
                    // Provide error feedback
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    
    func disconnect() {
        isLoading = true
        Task {
            do {
                _ = try await whatsappRepository.disconnectWhatsappAccount()
                await MainActor.run {
                    self.connectionState = .initial
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
                        // We have a session but it needs pairing
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
    
    deinit {
        pollingTimer?.invalidate()
        loadingTimeoutTimer?.invalidate()
    }
} 
