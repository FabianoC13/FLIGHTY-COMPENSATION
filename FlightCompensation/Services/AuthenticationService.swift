import Foundation
import FirebaseCore // Added for FirebaseApp
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import Combine

enum AuthState {
    case anonymous
    case authenticated(User)
    case unauthenticated
}

@MainActor
final class AuthenticationService: NSObject, ObservableObject {
    @Published var currentUser: User?
    @Published var isAnonymous: Bool = true
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    override init() {
        super.init()
        self.currentUser = auth.currentUser
        self.isAnonymous = auth.currentUser?.isAnonymous ?? true
        
        // Listen for auth state changes
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAnonymous = user?.isAnonymous ?? true
        }
    }
    
    // MARK: - Anonymous Auth
    func signInAnonymously() async throws {
        if auth.currentUser == nil {
            try await auth.signInAnonymously()
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        try auth.signOut()
    }
    
    // MARK: - Google Sign In
    func linkGoogleAccount(presenting viewController: UIViewController) async throws {
        // GIDSignIn v7 uses restorePreviousSignIn or signIn(withPresenting:)
        // Config is usually auto-loaded from Info.plist
        
        let gidResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        
        guard let idToken = gidResult.user.idToken?.tokenString else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing ID Token"])
        }
        let accessToken = gidResult.user.accessToken.tokenString
        
        // 2. Create Credential
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        // 3. Link or Sign In
        try await linkOrSignIn(credential: credential)
    }
    
    // MARK: - Apple Sign In
    func startAppleSignIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }
    
    // Internal helper to Link (upgrade) or Fallback to Sign In
    private func linkOrSignIn(credential: AuthCredential) async throws {
        guard let user = auth.currentUser else {
            try await auth.signIn(with: credential)
            return
        }
        
        do {
            let result = try await user.link(with: credential)
            print("✅ Account Linked: \(result.user.uid)")
        } catch {
            let nsError = error as NSError
            if nsError.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                print("⚠️ Credential already in use. Signing into that account instead.")
                try await auth.signIn(with: credential)
            } else {
                throw error
            }
        }
    }
}

// MARK: - Apple ID Delegate
extension AuthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let identityToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8) else {
                print("❌ Unable to fetch identity token")
                return
            }
            
            // Fix: rawNonce is required String. Using specific string for now (should be random in prod)
            let credential = OAuthProvider.credential(providerID: .apple, idToken: idTokenString, rawNonce: "UNSAFE_NONCE_FOR_DEMO")
            
            Task {
                do {
                    try await linkOrSignIn(credential: credential)
                } catch {
                    print("❌ Apple Sign In Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Sign in with Apple failed: \(error.localizedDescription)")
    }
}
