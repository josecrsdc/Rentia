import AuthenticationServices
import Testing
@testable import Rentia

@Suite("LoginViewModel")
@MainActor
struct LoginViewModelTests {
    private func makeVM(shouldThrow: Bool = false) -> (LoginViewModel, MockAuthenticationService) {
        let auth = MockAuthenticationService()
        auth.shouldThrow = shouldThrow
        let vm = LoginViewModel(authService: auth)
        return (vm, auth)
    }

    // MARK: - Initial state

    @Test func initialStateIsLoading() {
        let (vm, _) = makeVM()
        #expect(vm.isLoading == false)
    }

    @Test func initialStateShowError() {
        let (vm, _) = makeVM()
        #expect(vm.showError == false)
    }

    @Test func initialStateCurrentNonce() {
        let (vm, _) = makeVM()
        #expect(vm.currentNonce == nil)
    }

    // MARK: - prepareAppleSignIn

    @Test func prepareAppleSignInStoresNonce() {
        let (vm, _) = makeVM()
        _ = vm.prepareAppleSignIn()
        #expect(vm.currentNonce == "fixed-nonce-for-testing")
    }

    @Test func prepareAppleSignInReturnsHashedNonce() {
        let (vm, _) = makeVM()
        let result = vm.prepareAppleSignIn()
        #expect(result.hashedNonce == "hashed-fixed-nonce-for-testing")
    }

    @Test func currentNonceNilBeforePrepare() {
        let (vm, _) = makeVM()
        #expect(vm.currentNonce == nil)
    }

    // MARK: - signInWithGoogle error path

    @Test func signInWithGoogleOnErrorSetsShowError() async {
        let (vm, _) = makeVM(shouldThrow: true)
        vm.signInWithGoogle()
        await Task.yield()
        await Task.yield()
        #expect(vm.showError == true)
    }

    @Test func signInWithGoogleOnErrorIsNotLoading() async {
        let (vm, _) = makeVM(shouldThrow: true)
        vm.signInWithGoogle()
        await Task.yield()
        await Task.yield()
        #expect(vm.isLoading == false)
    }

    // MARK: - handleAppleSignIn

    @Test func handleAppleSignInCancelErrorDoesNotSetShowError() {
        let (vm, _) = makeVM()
        let cancelError = NSError(
            domain: ASAuthorizationError.errorDomain,
            code: ASAuthorizationError.canceled.rawValue
        )
        vm.handleAppleSignIn(result: .failure(cancelError))
        #expect(vm.showError == false)
    }

    @Test func handleAppleSignInGenericErrorSetsShowError() {
        let (vm, _) = makeVM()
        let genericError = NSError(domain: "TestDomain", code: 42)
        vm.handleAppleSignIn(result: .failure(genericError))
        #expect(vm.showError == true)
        #expect(vm.errorMessage != nil)
    }
}
