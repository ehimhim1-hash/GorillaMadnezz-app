import SwiftUI
import LocalAuthentication
import Combine

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isAdmin = false
    @Published var authenticationState: AuthenticationState = .pending
    @Published var showingAdminTransfer = false
    
    // Master admin device serial number
    private let masterAdminSerial = "JL2Q4GJ6JN"
    private let context = LAContext()
    
    enum AuthenticationState {
        case pending
        case authenticated
        case failed
        case unauthorized
        case transferMode
    }
    
    init() {
        checkDeviceStatus()
    }
    
    func authenticate() {
        let reason = "Authenticate to access Gorilla Madnezz"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.handleSuccessfulAuthentication()
                } else {
                    self?.authenticationState = .failed
                    // Fallback to passcode if Face ID fails
                    self?.authenticateWithPasscode()
                }
            }
        }
    }
    
    private func authenticateWithPasscode() {
        let reason = "Use your passcode to access Gorilla Madnezz"
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.handleSuccessfulAuthentication()
                } else {
                    self?.authenticationState = .failed
                }
            }
        }
    }
    
    private func handleSuccessfulAuthentication() {
        isAuthenticated = true
        checkAdminStatus()
        authenticationState = .authenticated
    }
    
    private func checkDeviceStatus() {
        let currentSerial = getCurrentDeviceSerial()
        isAdmin = (currentSerial == masterAdminSerial) || isApprovedAdmin(currentSerial)
    }
    
    private func checkAdminStatus() {
        let currentSerial = getCurrentDeviceSerial()
        isAdmin = (currentSerial == masterAdminSerial) || isApprovedAdmin(currentSerial)
    }
    
    private func getCurrentDeviceSerial() -> String {
        // In a real app, this would get the actual device serial number
        // For demo purposes, we'll simulate this
        return UIDevice.current.identifierForVendor?.uuidString ?? "DEMO_DEVICE"
    }
    
    private func isApprovedAdmin(_ serial: String) -> Bool {
        // Check CloudKit for approved admin devices
        let approvedAdmins = UserDefaults.standard.stringArray(forKey: "approvedAdminDevices") ?? []
        return approvedAdmins.contains(serial)
    }
    
    // MARK: - Admin Transfer Functions
    func initiateAdminTransfer() -> String {
        guard isAdmin else { return "" }
        
        let transferCode = generateTransferCode()
        let expirationTime = Date().addingTimeInterval(600) // 10 minutes
        
        UserDefaults.standard.set(transferCode, forKey: "activeTransferCode")
        UserDefaults.standard.set(expirationTime, forKey: "transferCodeExpiration")
        
        return transferCode
    }
    
    func completeAdminTransfer(with code: String) -> Bool {
        guard let storedCode = UserDefaults.standard.string(forKey: "activeTransferCode"),
              let expiration = UserDefaults.standard.object(forKey: "transferCodeExpiration") as? Date,
              Date() < expiration,
              code == storedCode else {
            return false
        }
        
        // Transfer admin rights to current device
        let newAdminSerial = getCurrentDeviceSerial()
        var approvedAdmins = UserDefaults.standard.stringArray(forKey: "approvedAdminDevices") ?? []
        
        if !approvedAdmins.contains(newAdminSerial) {
            approvedAdmins.append(newAdminSerial)
        }
        
        UserDefaults.standard.set(approvedAdmins, forKey: "approvedAdminDevices")
        
        // Clear transfer code
        UserDefaults.standard.removeObject(forKey: "activeTransferCode")
        UserDefaults.standard.removeObject(forKey: "transferCodeExpiration")
        
        // Update admin status
        isAdmin = true
        
        return true
    }
    
    private func generateTransferCode() -> String {
        let digits = "0123456789"
        var code = ""
        for _ in 0..<6 {
            code += String(digits.randomElement()!)
        }
        return code
    }
    
    func logout() {
        isAuthenticated = false
        isAdmin = false
        authenticationState = .pending
    }
    
    // MARK: - User Management
    func requestAccess(username: String, email: String) {
        // This would send a request to the admin device via CloudKit
        let request = AccessRequest(
            username: username,
            email: email,
            deviceSerial: getCurrentDeviceSerial(),
            requestDate: Date()
        )
        
        // Store locally and sync to CloudKit
        saveAccessRequest(request)
    }
    
    func approveUser(_ request: AccessRequest) {
        guard isAdmin else { return }
        
        var approvedUsers = UserDefaults.standard.stringArray(forKey: "approvedUsers") ?? []
        if !approvedUsers.contains(request.deviceSerial) {
            approvedUsers.append(request.deviceSerial)
        }
        
        UserDefaults.standard.set(approvedUsers, forKey: "approvedUsers")
        
        // Remove from pending requests
        removePendingRequest(request)
    }
    
    private func saveAccessRequest(_ request: AccessRequest) {
        // Implementation for saving access requests
    }
    
    private func removePendingRequest(_ request: AccessRequest) {
        // Implementation for removing processed requests
    }
}

// MARK: - Access Request Model
struct AccessRequest: Identifiable, Codable {
    let id = UUID()
    let username: String
    let email: String
    let deviceSerial: String
    let requestDate: Date
}
