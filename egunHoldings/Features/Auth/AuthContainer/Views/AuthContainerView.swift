import SwiftUI

struct AuthContainerView: View {
    let onLoginSuccess: (LoginSession) -> Void

    @StateObject private var loginViewModel = LoginViewModel()
    @State private var showsSignUp = false

    var body: some View {
        Group {
            if showsSignUp {
                SignUpView(
                    onBackToLogin: closeSignup,
                    onCompleted: { _ in
                        closeSignup()
                    }
                )
            } else {
                LoginView(
                    viewModel: loginViewModel,
                    onLoginSuccess: onLoginSuccess,
                    onTapSignUp: {
                        loginViewModel.resetError()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showsSignUp = true
                        }
                    }
                )
            }
        }
    }

    private func closeSignup() {
        loginViewModel.resetError()
        withAnimation(.easeInOut(duration: 0.2)) {
            showsSignUp = false
        }
    }
}

#Preview {
    AuthContainerView(onLoginSuccess: { _ in })
}
