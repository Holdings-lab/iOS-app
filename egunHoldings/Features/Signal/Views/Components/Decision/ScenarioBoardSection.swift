import SwiftUI

struct ScenarioBoardSection: View {
    let scenarios: [PolicyScenarioSnapshot]
    let ledgers: [DecisionEvidenceLedger]

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("시나리오 비교")
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.foreground)

                ForEach(scenarios) { scenario in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(scenario.accentColor.opacity(0.18))
                            .frame(width: 10)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(scenario.title)
                                    .font(.pretendard(13, weight: .semibold))
                                    .foregroundStyle(Color.foreground)
                                Spacer()
                                Text(scenario.portfolioBias)
                                    .font(.pretendard(11, weight: .semibold))
                                    .foregroundStyle(scenario.accentColor)
                            }
                            Text(scenario.targetPositioning)
                                .font(.pretendard(12, weight: .semibold))
                                .foregroundStyle(Color.foreground)
                            Text(scenario.note)
                                .font(.pretendard(11, weight: .medium))
                                .foregroundStyle(Color.mutedForeground)
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(16)
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("근거 장부")
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(Color.foreground)

                ForEach(ledgers) { ledger in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(ledger.title)
                            .font(.pretendard(13, weight: .semibold))
                            .foregroundStyle(Color.foreground)

                        ForEach(Array(ledger.supportingEvidence.enumerated()), id: \.offset) { _, line in
                            Label(line, systemImage: "checkmark.circle.fill")
                                .font(.pretendard(11, weight: .medium))
                                .foregroundStyle(Color.foreground)
                        }

                        Text("반대 근거: \(ledger.counterEvidence)")
                            .font(.pretendard(11, weight: .medium))
                            .foregroundStyle(Color.policyAmber)

                        HStack {
                            Text(ledger.sourceText)
                            Spacer()
                            Text(ledger.expiresAtText)
                        }
                        .font(.pretendard(10, weight: .medium))
                        .foregroundStyle(Color.mutedForeground)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(16)
            .glassCard()
        }
    }
}
