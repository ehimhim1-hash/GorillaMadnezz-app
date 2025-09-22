//
//  AuthenticationView.swift
//  GorillaMadnezz
//
//  Authentication screen with Face ID/Touch ID and admin controls
//

import SwiftUI
import LocalAuthentication

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAuthenticating = false
    @State private var showAdminTransfer = false
    @State private var animateGorilla = false
    @State private var showWelcome = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color.gray.opacity(0.8), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background particles
            ParticleView()
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo and Title
                logoSection
                
                // Authentication Status
                authenticationStatus
                
                // Main Authentication Button
                authenticationButton
                
                // Admin Controls (if applicable)
                if authManager.isAdmin {
                    adminControls
                }
                
                // Device Info
                deviceInfoSection
                
                Spacer()
                
                // Footer
                footerSection
            }
            .padding()
        }
        .onAppear {
            startAnimations()
            checkDeviceStatus()
        }
        .alert("Authentication", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showAdminTransfer) {
            AdminTransferView()
        }
    }
    
    // MARK: - UI Components
    
    private var logoSection: some View {
        VStack(spacing: 20) {
            // Animated Gorilla Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.3), Color.black],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateGorilla ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGorilla)
                
                Text("🦍")
                    .font(.system(size: 60))
                    .rotationEffect(.degrees(animateGorilla ? 5 : -5))
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGorilla)
            }
            
            // App Title
            VStack(spacing: 8) {
                Text("GORILLA")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .tracking(3)
                
                Text("MADNEZZ")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .tracking(2)
                
                Text("Shadow Training System")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .tracking(1)
            }
        }
    }
    
    private var authenticationStatus: some View {
        VStack(spacing: 15) {
            // Device Status
            HStack {
                Image(systemName: authManager.isAuthorizedDevice ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundColor(authManager.isAuthorizedDevice ? .green : .orange)
                    .font(.title2)
                
                Text(authManager.isAuthorizedDevice ? "Authorized Device" : "Device Verification Required")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(12)
            
            // Admin Status (if admin)
            if authManager.isAdmin {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    
                    Text("Master Admin Device")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }
    
    private var authenticationButton: some View {
        VStack(spacing: 20) {
            // Main Auth Button
            Button(action: {
                authenticateUser()
            }) {
                HStack {
                    if isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: getBiometricIcon())
                            .font(.title2)
                    }
                    
                    Text(isAuthenticating ? "Authenticating..." : "Unlock with \(getBiometricType())")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.purple.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
                .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .disabled(isAuthenticating)
            .scaleEffect(isAuthenticating ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isAuthenticating)
            
            // Alternative authentication
            Button("Enter Passcode") {
                authenticateWithPasscode()
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            .underline()
        }
    }
    
    private var adminControls: some View {
        VStack(spacing: 15) {
            Text("Admin Controls")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top)
            
            HStack(spacing: 15) {
                // Transfer Admin Button
                Button(action: {
                    showAdminTransfer = true
                }) {
                    VStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title2)
                        Text("Transfer\nAdmin")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(.yellow)
                    .frame(width: 80, height: 60)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                }
                
                // Reset System Button
                Button(action: {
                    resetSystem()
                }) {
                    VStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                        Text("Reset\nSystem")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(.red)
                    .frame(width: 80, height: 60)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                }
                
                // Emergency Access Button
                Button(action: {
                    emergencyAccess()
                }) {
                    VStack {
                        Image(systemName: "sos")
                            .font(.title2)
                        Text("Emergency\nAccess")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(.orange)
                    .frame(width: 80, height: 60)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var deviceInfoSection: some View {
        VStack(spacing: 8) {
            Text("Device Information")
                .font(.caption)
                .foregroundColor(.gray)
            
            VStack(spacing: 4) {
                HStack {
                    Text("Serial:")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(authManager.getCurrentDeviceSerial())
                        .font(.caption2)
                        .fontFamily(.monospaced)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Status:")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(authManager.isAdmin ? "Master Admin" : "Standard User")
                        .font(.caption2)
                        .foregroundColor(authManager.isAdmin ? .yellow : .blue)
                }
                
                HStack {
                    Text("Biometric:")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(getBiometricType())
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(10)
    }
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("🔒 Secure Access System")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("Powered by Military-Grade Security")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.8))
        }
    }
    
    // MARK: - Helper Functions
    
    private func startAnimations() {
        animateGorilla = true
    }
    
    private func checkDeviceStatus() {
        // Automatically check device authorization
        authManager.checkDeviceAuthorization()
    }
    
    private func authenticateUser() {
        isAuthenticating = true
        
        authManager.authenticate { success, error in
            DispatchQueue.main.async {
                isAuthenticating = false
                
                if success {
                    showWelcome = true
                    withAnimation(.easeInOut(duration: 0.5)) {
                        // Authentication successful - handled by main app
                    }
                } else {
                    alertMessage = error ?? "Authentication failed. Please try again."
                    showingAlert = true
                }
            }
        }
    }
    
    private func authenticateWithPasscode() {
        authManager.authenticateWithPasscode { success, error in
            DispatchQueue.main.async {
                if !success {
                    alertMessage = error ?? "Passcode authentication failed."
                    showingAlert = true
                }
            }
        }
    }
    
    private func getBiometricType() -> String {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                return "Face ID"
            case .touchID:
                return "Touch ID"
            default:
                return "Biometric ID"
            }
        }
        return "Passcode"
    }
    
    private func getBiometricIcon() -> String {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            default:
                return "lock.shield"
            }
        }
        return "key"
    }
    
    private func resetSystem() {
        alertMessage = "System reset initiated. All data will be cleared."
        showingAlert = true
        // Implement reset logic
    }
    
    private func emergencyAccess() {
        alertMessage = "Emergency access protocol activated."
        showingAlert = true
        // Implement emergency access
    }
}

// MARK: - Particle Animation View
struct ParticleView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: animate ? -50 : UIScreen.main.bounds.height + 50
                    )
                    .animation(
                        .linear(duration: Double.random(in: 3...8))
                        .repeatForever(autoreverses: false)
                        .delay(Double.random(in: 0...5)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Admin Transfer View
struct AdminTransferView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var targetDeviceSerial = ""
    @State private var confirmationCode = ""
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("🔄 Admin Transfer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Transfer admin privileges to another device")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Target Device Serial")
                        .font(.headline)
                    
                    TextField("Enter device serial number", text: $targetDeviceSerial)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.monospaced)
                    
                    Text("Confirmation Code")
                        .font(.headline)
                    
                    TextField("Enter 6-digit code", text: $confirmationCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                .padding()
                
                Button("Transfer Admin Rights") {
                    transferAdmin()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Admin Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
        }
    }
    
    private func transferAdmin() {
        authManager.transferAdminRights(to: targetDeviceSerial, confirmationCode: confirmationCode) { success in
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}
