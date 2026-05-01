import SwiftUI

struct AuthContainerView: View {
    @ObservedObject var viewModel: AppFlowViewModel
    @State private var showsSignUp = false

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
                    onLogin: { email, password in
                        viewModel.login(email: email, password: password)
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
        viewModel.resetAuthError()
        withAnimation(.easeInOut(duration: 0.2)) {
            showsSignUp = false
        }
    }
}

#Preview {
    AuthContainerView(viewModel: AppFlowViewModel())
}
