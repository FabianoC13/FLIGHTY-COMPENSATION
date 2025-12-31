import LocalAuthentication
import Foundation

class BiometricService {
    static let shared = BiometricService()
    
    private init() {}
    
    func authenticateUser(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return await withCheckedContinuation { continuation in
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                    if success {
                        continuation.resume(returning: true)
                    } else {
                        print("Biometric authentication failed: \(String(describing: authenticationError))")
                        continuation.resume(returning: false)
                    }
                }
            }
        } else {
            // Fallback to device passcode if biometrics are not available (optional, depending on strictness)
            // For now, we'll return false or true depending on requirements. 
            // Often in simulators, biometrics might not be enrolled. 
            // We can try .deviceOwnerAuthentication which includes passcode.
             if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                return await withCheckedContinuation { continuation in
                    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                        continuation.resume(returning: success)
                    }
                }
            }
            
            print("Biometric authentication not available: \(String(describing: error))")
            return false
        }
    }
}
