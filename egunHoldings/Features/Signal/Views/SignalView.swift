import SwiftUI

struct SignalView: View {
    @ObservedObject var viewModel: SignalViewModel

    var body: some View {
        PFContentScrollView(spacing: 20, scrollsToTopOnAppear: true) {
            SignalHeaderView()

            ActionLaneBoardSection(actionOptions: viewModel.decisionDashboard.actionOptions)

            TransmissionMatchSection(matches: viewModel.decisionDashboard.transmissionMatches)

            ScenarioBoardSection(
                scenarios: viewModel.decisionDashboard.scenarios,
                ledgers: viewModel.decisionDashboard.ledgers
            )
        }
        .policyFinanceDarkTabChrome()
    }
}

#Preview {
    NavigationStack {
        SignalView(viewModel: SignalViewModel())
    }
}
