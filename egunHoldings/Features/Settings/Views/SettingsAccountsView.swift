import SwiftUI

struct SettingsAccountsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onBack: () -> Void

    @State private var isAdding = false
    @State private var removeTarget: String?

    private static let statusMeta: [AccountStatus: (tone: BadgeTone, label: String)] = [
        .ok: (.ok, "정상 연결"),
        .reauth: (.warn, "재인증 필요"),
        .error: (.error, "연결 끊김")
    ]

    var body: some View {
        VStack(spacing: 0) {
            SettingsNavHeader(title: "연결된 계좌", onBack: onBack)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    CalloutView(tone: .info, icon: "info.circle.fill") {
                        Text("조회 전용으로 연결돼요. 주문 권한은 요청하지 않고, 언제든 해제할 수 있어요.")
                    }
                    .padding(.top, 14)

                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.accounts.enumerated()), id: \.element.id) { index, account in
                            if index > 0 { SettingsDivider() }
                            accountRow(account)
                        }
                    }
                    .background(Color.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 2)
                    .padding(.top, 14)

                    if isAdding {
                        addBrokerPanel
                    } else if !viewModel.availableBrokers.isEmpty {
                        Button(action: { isAdding = true }) {
                            Text("+ 증권사 추가")
                                .font(.pretendard(13.5, weight: .bold))
                                .foregroundStyle(Color.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                        .foregroundStyle(Color.hairline)
                                }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 14)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .background(Color.canvas.ignoresSafeArea())
        .overlay {
            SettingsConfirmModal(
                isPresented: removeTarget != nil,
                title: "연결을 해제할까요?",
                desc: removeTarget.flatMap { SettingsMockData.brokerByID[$0]?.name }.map {
                    "\($0) 계좌 연결을 해제하면 이 계좌 기반 분석이 더 이상 표시되지 않아요."
                },
                confirmLabel: "해제하기",
                danger: true,
                onConfirm: {
                    if let removeTarget { viewModel.removeBroker(id: removeTarget) }
                    removeTarget = nil
                },
                onCancel: { removeTarget = nil }
            )
        }
    }

    @ViewBuilder
    private func accountRow(_ account: ConnectedAccount) -> some View {
        if let meta = SettingsMockData.brokerByID[account.brokerId] {
            accountRowContent(account: account, meta: meta)
        }
    }

    private func accountRowContent(account: ConnectedAccount, meta: BrokerMeta) -> some View {
        let busy = viewModel.busyAccountKey == account.brokerId
        let status = Self.statusMeta[account.status] ?? (.ok, "정상 연결")

        return (
            HStack(spacing: 12) {
                Text(meta.glyph)
                    .font(.pretendard(14, weight: .bold))
                    .foregroundStyle(meta.tint)
                    .frame(width: 40, height: 40)
                    .background(meta.bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(meta.name)
                        .font(.pretendard(14.5, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    HStack(spacing: 6) {
                        StatusBadge(tone: status.tone, text: busy ? "재인증 중…" : status.label)

                        if account.status == .ok, !busy, let lastSync = account.lastSync {
                            Text("동기화 \(lastSync)")
                                .font(.pretendard(12, weight: .regular))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }

                Spacer(minLength: 8)

                if account.status == .ok {
                    Button("해제") { removeTarget = account.brokerId }
                        .buttonStyle(.plain)
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(Color.brand)
                } else {
                    Button {
                        Task { await viewModel.reauthenticate(brokerId: account.brokerId) }
                    } label: {
                        Text(busy ? "확인 중…" : (account.status == .reauth ? "재인증" : "다시 연결"))
                            .font(.pretendard(12.5, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.brand, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(busy)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        )
    }

    private var addBrokerPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.availableBrokers) { broker in
                let busy = viewModel.busyAccountKey == "add-\(broker.id)"

                Button {
                    guard viewModel.busyAccountKey == nil else { return }
                    Task { await viewModel.addBroker(id: broker.id) }
                } label: {
                    HStack(spacing: 12) {
                        Text(broker.glyph)
                            .font(.pretendard(12, weight: .bold))
                            .foregroundStyle(broker.tint)
                            .frame(width: 32, height: 32)
                            .background(broker.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                        Text(broker.name)
                            .font(.pretendard(14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)

                        Spacer()

                        Text(busy ? "연결 중…" : "연결")
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.elevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.hairline, lineWidth: 1.5)
                    }
                    .opacity(busy ? 0.6 : 1)
                }
                .buttonStyle(.plain)
            }

            Button("닫기") { isAdding = false }
                .buttonStyle(.plain)
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(Color.brand)
                .padding(.top, 2)
        }
        .padding(10)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 2)
        .padding(.top, 14)
    }
}
