import SwiftUI

struct AuthContainerView: View {
    let onLoginSuccess: (AppUserSession) -> Void

    @StateObject private var viewModel = AuthViewModel()
    @State private var showsSignUp = false
    @State private var isLoginInFlight = false

    var body: some View {
        Group {
            if showsSignUp {
                SignUpView(
                    errorMessage: viewModel.authErrorMessage,
                    onBackToLogin: closeSignup,
                    onResetError: {
                        viewModel.resetAuthError()
                    },
                    onSignUp: { name, email, password, confirmPassword, agreed in
                        await viewModel.signUp(
                            name: name,
                            email: email,
                            password: password,
                            confirmPassword: confirmPassword,
                            agreedToTerms: agreed
                        )
                    },
                    onCompleted: { _ in
                        closeSignup()
                    }
                )
            } else {
                LoginView(
                    errorMessage: viewModel.authErrorMessage,
                    isLoading: isLoginInFlight,
                    onLogin: { email, password in
                        guard !isLoginInFlight else { return }
                        isLoginInFlight = true

                        Task {
                            if let session = await viewModel.login(email: email, password: password) {
                                onLoginSuccess(session)
                                return
                            }

                            isLoginInFlight = false
                        }
                    },
                    onSocialLogin: { provider in
                        viewModel.login(with: provider)
                    },
                    onTapSignUp: {
                        viewModel.resetAuthError()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showsSignUp = true
                        }
                    }
                )
            }
        }
    }

    private func closeSignup() {
        isLoginInFlight = false
        viewModel.resetAuthError()
        withAnimation(.easeInOut(duration: 0.2)) {
            showsSignUp = false
        }
    }
}

#Preview {
    AuthContainerView(onLoginSuccess: { _ in })
}
