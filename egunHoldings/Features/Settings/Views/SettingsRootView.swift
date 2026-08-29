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
                SettingsLargeHeader(eyebrow: "계정 및 앱 관리", title: "설정", onClose: { dismiss() })

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        if viewModel.issueCount > 0 {
                            accountIssueBanner
                        }

                        profileCard

                        notificationSection
                        investSection
                        accountManagementSection

                        Text("v3.1.0")
                            .font(.pretendard(11.5, weight: .regular))
                            .foregroundStyle(Color.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 24)
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.canvas.ignoresSafeArea())
            .navigationDestination(for: SettingsRoute.self) { route in
                // 세부 화면들은 SettingsNavHeader가 자체 뒤로가기 버튼을 그린다. `.toolbar(.hidden, for:)`를
                // 루트 콘텐츠에만 걸어두면 push된 화면에는 적용되지 않아(각 push는 별도 페이지로 취급되어
                // 툴바 가시성이 상속되지 않는다) 시스템 백 버튼이 다시 나타나 화살표가 두 개 겹쳐 보인다.
                // 그래서 destination closure 안, 즉 실제로 표시되는 뷰 쪽에 직접 걸어야 한다.
                Group {
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
                .toolbar(.hidden, for: .navigationBar)
            }
            .toolbar(.hidden, for: .navigationBar)
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
        .task { await viewModel.loadSettings() }
    }

    /// 피그마 `설정 / 오류`(7:2220) 상단 배너. 계좌 인증 만료 건이 있을 때만 뜬다.
    private var accountIssueBanner: some View {
        Button(action: { path.append(.accounts) }) {
            HStack(spacing: 10) {
                Text("연결된 계정 \(viewModel.issueCount)개의 인증이 만료됐어요.")
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(Color.warning)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("확인")
                    .font(.pretendard(12.5, weight: .bold))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color.warningBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.warningBorder, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.bottom, 12)
    }

    private var profileCard: some View {
        Button(action: { path.append(.accounts) }) {
            HStack(spacing: 13) {
                // 피그마 7:2028 — 52pt 라운드 사각형에 브랜드 그라디언트(원형 아바타에서 변경).
                Text(String(viewModel.displayName.prefix(1)))
                    .font(.pretendard(18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color.brand, Color.brandLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 17, style: .continuous)
                    )

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
                            .background(Color.brandChipBg, in: Capsule())
                    }

                    Text(viewModel.email)
                        .font(.pretendard(12, weight: .regular))
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textQuaternary)
            }
            .padding(17)
            .background(Color.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var investSection: some View {
        SettingsSection(title: "투자 설정") {
            SettingsRow(title: "투자 목표", icon: "target", sub: viewModel.goalSummary, onTap: { path.append(.goal) })
            SettingsDivider()
            SettingsRow(title: "연결 계좌", icon: "building.columns", sub: "\(viewModel.connectedCount)개", onTap: { path.append(.accounts) }) {
                viewModel.issueCount > 0 ? AnyView(StatusBadge(tone: .warn, text: "주의 필요")) : AnyView(chevron)
            }
            SettingsDivider()
            SettingsRow(title: "관심 정책", icon: "doc.text", sub: viewModel.policyCategorySummary, onTap: { path.append(.policyCategories) })
        }
    }

    private var notificationSection: some View {
        SettingsSection(title: "알림") {
            SettingsRow(title: "정책 변화 알림", icon: "bell.badge", sub: "중요 정책 변화를 알려드려요") {
                SettingsToggle(isOn: Binding(
                    get: { viewModel.policyChangeAlert },
                    set: viewModel.setPolicyChangeAlert
                ))
            }
            SettingsDivider()
            SettingsRow(title: "오늘 브리핑 시간", icon: "sun.max", sub: "선택한 시간에 오늘의 브리핑을 보내드려요") {
                Picker("오늘 브리핑 시간", selection: Binding(
                    get: { viewModel.briefingTime },
                    set: viewModel.setBriefingTime
                )) {
                    ForEach(viewModel.briefingTimeOptions, id: \.self) { time in
                        Text(time).tag(time)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            SettingsDivider()
            SettingsRow(title: "테스트 알림 보내기", icon: "arrow.up.right", sub: "기기에 알림이 도착하는지 확인해요", onTap: viewModel.sendTestNotification) {
                if viewModel.isSendingTestNotification {
                    ProgressView().controlSize(.small)
                } else {
                    chevron
                }
            }
        }
    }

    private var accountManagementSection: some View {
        SettingsSection(title: "계정") {
            SettingsRow(title: "이메일", icon: "envelope", sub: viewModel.email)
            SettingsDivider()
            SettingsRow(title: "비밀번호 변경", icon: "lock", onTap: { activeModal = .password })
            SettingsDivider()
            SettingsRow(title: "로그아웃", icon: "rectangle.portrait.and.arrow.right", onTap: { activeModal = .logout })
            SettingsDivider()
            SettingsRow(title: "회원 탈퇴", icon: "person.crop.circle.badge.xmark", danger: true, onTap: { activeModal = .delete })
            SettingsDivider()
            SettingsRow(title: "개인정보 처리방침", icon: "hand.raised", onTap: viewModel.notifyDocumentPending)
            SettingsDivider()
            SettingsRow(title: "이용약관", icon: "doc.plaintext", onTap: viewModel.notifyDocumentPending)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.textQuaternary)
    }
}

#Preview {
    SettingsRootView(notificationCenter: AppNotificationCenter.shared)
}
