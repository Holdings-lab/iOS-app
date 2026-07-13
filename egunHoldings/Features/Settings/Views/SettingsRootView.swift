import SwiftUI

enum SettingsRoute: Hashable {
    case accounts
    case investProfile
    case goal
    case watchlist
    case policyCategories
}

private enum SettingsModal: Identifiable {
    case password
    case logout
    case delete

    var id: Int { hashValue }
}

struct SettingsRootView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var path: [SettingsRoute] = []
    @State private var activeModal: SettingsModal?

    init(notificationCenter: AppNotificationCenter) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(notificationCenter: notificationCenter))
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                SettingsNavHeader(title: "설정", onBack: { dismiss() })

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileCard

                        investSection
                        accountsSection
                        notificationSection
                        appSection
                        accountManagementSection

                        Text("v3.1.0")
                            .font(.pretendard(11.5, weight: .regular))
                            .foregroundStyle(Color.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 24)
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }
            }
            .background(Color.canvas.ignoresSafeArea())
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .accounts:
                    SettingsAccountsView(viewModel: viewModel, onBack: { path.removeLast() })
                case .investProfile:
                    SettingsInvestProfileView(viewModel: viewModel, onBack: { path.removeLast() })
                case .goal:
                    SettingsGoalView(viewModel: viewModel, onBack: { path.removeLast() })
                case .watchlist:
                    SettingsWatchlistView(viewModel: viewModel, onBack: { path.removeLast() })
                case .policyCategories:
                    SettingsPolicyCategoriesView(viewModel: viewModel, onBack: { path.removeLast() })
                }
            }
        }
        .overlay(alignment: .bottom) {
            SettingsToast(message: viewModel.toast)
        }
        .overlay {
            SettingsPasswordModal(
                isPresented: activeModal == .password,
                onClose: { activeModal = nil },
                notify: viewModel.notify
            )
        }
        .overlay {
            SettingsConfirmModal(
                isPresented: activeModal == .logout,
                title: "로그아웃할까요?",
                desc: "다시 로그인하면 이어서 사용할 수 있어요.",
                confirmLabel: "로그아웃",
                onConfirm: {
                    activeModal = nil
                    viewModel.notify("로그아웃했어요")
                },
                onCancel: { activeModal = nil }
            )
        }
        .overlay {
            SettingsConfirmModal(
                isPresented: activeModal == .delete,
                title: "정말 탈퇴하시겠어요?",
                desc: "계정과 모든 설정, 연결된 계좌 정보가 삭제되고 되돌릴 수 없어요.",
                confirmLabel: "탈퇴하기",
                danger: true,
                onConfirm: {
                    activeModal = nil
                    viewModel.notify("탈퇴 요청을 접수했어요")
                },
                onCancel: { activeModal = nil }
            )
        }
        .preferredColorScheme(.light)
    }

    private var profileCard: some View {
        Button(action: { path.append(.accounts) }) {
            HStack(spacing: 14) {
                Text(String(viewModel.displayName.prefix(1)))
                    .font(.pretendard(18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 48, height: 48)
                    .background(Color.brand, in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(viewModel.displayName)
                            .font(.pretendard(16, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        Text(viewModel.investmentProfile.title)
                            .font(.pretendard(11, weight: .bold))
                            .foregroundStyle(Color.brand)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.brandTintBg, in: Capsule())
                    }

                    (
                        Text("계좌 \(viewModel.connectedCount)개 연결됨")
                            .foregroundStyle(Color.textSecondary)
                        + (viewModel.issueCount > 0
                           ? Text(" · 확인 필요 \(viewModel.issueCount)건").foregroundStyle(Color.warning)
                           : Text(""))
                    )
                    .font(.pretendard(12.5, weight: .medium))
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(16)
            .background(Color.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.top, 14)
    }

    private var investSection: some View {
        SettingsSection(title: "투자 설정") {
            SettingsRow(title: "투자 프로필", sub: viewModel.investProfileSummary, onTap: { path.append(.investProfile) })
            SettingsDivider()
            SettingsRow(title: "목표 설정", sub: viewModel.goalSummary, onTap: { path.append(.goal) })
            SettingsDivider()
            SettingsRow(title: "관심 분야", sub: viewModel.watchSectorSummary, onTap: { path.append(.watchlist) })
            SettingsDivider()
            SettingsRow(title: "관심 정책 카테고리", sub: viewModel.policyCategorySummary, onTap: { path.append(.policyCategories) })
        }
    }

    private var accountsSection: some View {
        SettingsSection(title: "연결된 계좌") {
            SettingsRow(title: "증권사 계좌 관리", sub: viewModel.connectedBrokerNames, onTap: { path.append(.accounts) }) {
                if viewModel.issueCount > 0 {
                    StatusBadge(tone: .warn, text: "확인 필요")
                } else {
                    chevron
                }
            }
        }
    }

    private var notificationSection: some View {
        SettingsSection(title: "알림") {
            SettingsRow(title: "푸시 알림", sub: viewModel.pushPermissionText) {
                Button(action: viewModel.sendTestNotification) {
                    Text(viewModel.isSendingTestNotification ? "전송 중" : "테스트")
                        .font(.pretendard(12.5, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.subtle, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSendingTestNotification)
            }

            SettingsDivider()

            SettingsRow(title: "하락 알림", sub: "포트폴리오가 고점 대비 크게 하락하면 알려드려요") {
                SettingsToggle(isOn: $viewModel.notificationPreferences.dropAlertOn)
            }

            if viewModel.notificationPreferences.dropAlertOn {
                SettingsDivider()
                sensitivityRow(label: "WATCH 민감도", selection: $viewModel.notificationPreferences.watchSensitivity)
                SettingsDivider()
                sensitivityRow(label: "ALERT 민감도", selection: $viewModel.notificationPreferences.alertSensitivity)
            }

            SettingsDivider()

            SettingsRow(title: "방해 금지 시간대", sub: "22:00 – 07:00 · 다음 업데이트에 추가돼요", onTap: viewModel.notifyComingSoon) {
                StatusBadge(tone: .soon, text: "준비 중")
            }

            SettingsDivider()

            SettingsRow(title: "시장 신호 알림", sub: "발동 기준은 아직 준비 중이에요") {
                SettingsToggle(isOn: $viewModel.notificationPreferences.marketSignalOn)
            }
        }
    }

    private func sensitivityRow(label: String, selection: Binding<Sensitivity>) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(label)
                .font(.pretendard(12.5, weight: .semibold))
                .foregroundStyle(Color.textSecondary)

            SettingsSegmentedControl(
                selection: selection,
                options: Sensitivity.allCases.map { ($0, $0.title) }
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    private var appSection: some View {
        SettingsSection(title: "앱 설정") {
            VStack(alignment: .leading, spacing: 9) {
                Text("테마")
                    .font(.pretendard(12.5, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)

                SettingsSegmentedControl(
                    selection: $viewModel.appPreferences.theme,
                    options: AppTheme.allCases.map { ($0, $0.title) }
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)

            SettingsDivider()

            SettingsRow(title: "데이터 사용 최적화", sub: "이미지 절약 모드") {
                SettingsToggle(isOn: $viewModel.appPreferences.dataSaverOn)
            }
        }
    }

    private var accountManagementSection: some View {
        SettingsSection(title: "계정") {
            SettingsRow(title: "이메일", sub: viewModel.email)
            SettingsDivider()
            SettingsRow(title: "비밀번호 변경", onTap: { activeModal = .password })
            SettingsDivider()
            SettingsRow(title: "로그아웃", onTap: { activeModal = .logout })
            SettingsDivider()
            SettingsRow(title: "회원 탈퇴", danger: true, onTap: { activeModal = .delete })
            SettingsDivider()
            SettingsRow(title: "개인정보 처리방침", onTap: viewModel.notifyDocumentPending)
            SettingsDivider()
            SettingsRow(title: "이용약관", onTap: viewModel.notifyDocumentPending)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.textTertiary)
    }
}

#Preview {
    SettingsRootView(notificationCenter: AppNotificationCenter.shared)
}
