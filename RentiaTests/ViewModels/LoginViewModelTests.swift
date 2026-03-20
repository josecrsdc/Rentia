import AuthenticationServices
import Testing
@testable import Rentia

@Suite("LoginViewModel")
@MainActor
struct LoginViewModelTests {
    private func waitForAsyncWork() async {
        await Task.yield()
        await Task.yield()
    }

    private func makeVM(shouldThrow: Bool = false) -> (LoginViewModel, MockAuthenticationService) {
        let auth = MockAuthenticationService()
        auth.shouldThrow = shouldThrow
        let vm = LoginViewModel(authService: auth)
        return (vm, auth)
    }

    @Test func initialStateIsClean() {
        let (vm, _) = makeVM()
        #expect(vm.isLoading == false)
        #expect(vm.showError == false)
        #expect(vm.currentNonce == nil)
    }

    // MARK: - prepareAppleSignIn

    @Test func prepareAppleSignInStoresAndHashesNonce() {
        let (vm, _) = makeVM()
        let result = vm.prepareAppleSignIn()
        #expect(result.nonce == "fixed-nonce-for-testing")
        #expect(vm.currentNonce == "fixed-nonce-for-testing")
        #expect(result.hashedNonce == "hashed-fixed-nonce-for-testing")
    }

    // MARK: - signInWithGoogle

    @Test func signInWithGoogleOnSuccessCallsServiceAndClearsState() async {
        let (vm, auth) = makeVM()
        vm.errorMessage = "old"
        vm.showError = true
        vm.signInWithGoogle()
        await waitForAsyncWork()
        #expect(auth.signInGoogleCallCount == 1)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.showError == true)
    }

    @Test func signInWithGoogleOnErrorSetsShowErrorAndClearsLoading() async {
        let (vm, _) = makeVM(shouldThrow: true)
        vm.signInWithGoogle()
        await waitForAsyncWork()
        #expect(vm.showError == true)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage != nil)
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
