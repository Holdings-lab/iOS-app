import SwiftUI

struct CheckpointHeaderView: View {
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("정책 체크포인트")
                .font(PSFont.title(22))
                .foregroundStyle(PSColor.textPrimary)

            Text(summary)
                .font(PSFont.caption(11))
                .foregroundStyle(Color.white.opacity(0.40))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WeeklyPolicyAccordionSection: View {
    let policyEvents: [CheckpointPolicyEvent]
    let isExpanded: (CheckpointPolicyEvent) -> Bool
    let onToggle: (CheckpointPolicyEvent) -> Void
    let onCheckpointTap: (CheckpointItem) -> Void
    let decisionsFor: (Int) -> [CheckpointDecisionItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("이번 주 일정")

            VStack(spacing: 10) {
                ForEach(policyEvents) { policy in
                    PolicyScheduleCard(
                        policy: policy,
                        isExpanded: isExpanded(policy),
                        onToggle: { onToggle(policy) },
                        onCheckpointTap: onCheckpointTap,
                        decisions: decisionsFor(policy.id)
                    )
                }
            }
        }
    }
}

private struct PolicyScheduleCard: View {
    let policy: CheckpointPolicyEvent
    let isExpanded: Bool
    let onToggle: () -> Void
    let onCheckpointTap: (CheckpointItem) -> Void
    let decisions: [CheckpointDecisionItem]

    var body: some View {
        Button(action: onToggle) {
            PSGlassCard(variant: policy.isToday ? .primary : .secondary, padding: 14) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(policy.date)
                                .font(PSFont.semibold(13))
                                .foregroundStyle(policy.isToday ? PSColor.electricBlue : PSColor.textPrimary)
                                .monospacedDigit()

                            Text(policy.day)
                                .font(PSFont.caption(10))
                                .foregroundStyle(Color.white.opacity(0.40))
                        }
                        .frame(width: 46, alignment: .leading)

                        HStack(spacing: 7) {
                            PolicyColorDot(color: policy.color, size: 7)
                            Text(policy.title)
                                .font(PSFont.semibold(13))
                                .foregroundStyle(PSColor.textPrimary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        if policy.isToday {
                            PSStatusChip(label: "오늘", color: PSColor.electricBlue, bgOpacity: 0.10)
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }

                    if isExpanded {
                        policyDetail
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .buttonStyle(PSPressStyle())
    }

    private var policyDetail: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(policy.institution)
                    .font(PSFont.caption(11))
                    .foregroundStyle(Color.white.opacity(0.50))

                Spacer()

                PSStatusChip(label: "내 자산 \(policy.exposure)%", color: policy.color, bgOpacity: 0.10)
            }

            VStack(alignment: .leading, spacing: 9) {
                detailLabel("확인할 것")

                ForEach(policy.checkpoints) { checkpoint in
                    Button {
                        onCheckpointTap(checkpoint)
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(policy.color.opacity(0.70))
                                .padding(.top, 4)

                            Text(checkpoint.text)
                                .font(PSFont.body(12))
                                .foregroundStyle(Color.white.opacity(0.65))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if !decisions.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    detailLabel("지금 어떻게 할까")

                    ForEach(decisions) { item in
                        HStack(alignment: .top, spacing: 8) {
                            JudgmentTypeBadge(type: item.type)

                            Text(item.title)
                                .font(PSFont.body(12))
                                .foregroundStyle(Color.white.opacity(0.65))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(14)
        .padding(.leading, 16)
        .background(policy.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(policy.color.opacity(0.15), lineWidth: 1)
        }
    }

    private func detailLabel(_ text: String) -> some View {
        Text(text)
            .font(PSFont.caption(11))
            .foregroundStyle(Color.white.opacity(0.40))
    }
}

struct SavedCheckpointsSection: View {
    @Binding var selectedFilter: CheckpointFilter
    let checkpoints: [CheckpointItem]
    let onToggleComplete: (CheckpointItem) -> Void
    let onDetail: (CheckpointItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                sectionTitle("내 체크리스트")
                Spacer()
                CheckpointFilterSegment(selection: $selectedFilter)
            }

            if checkpoints.isEmpty {
                EmptyCheckpointState()
            } else {
                VStack(spacing: 10) {
                    ForEach(checkpoints) { checkpoint in
                        SavedCheckpointCard(
                            checkpoint: checkpoint,
                            onToggleComplete: { onToggleComplete(checkpoint) },
                            onDetail: { onDetail(checkpoint) }
                        )
                    }
                }
            }
        }
    }
}

private struct CheckpointFilterSegment: View {
    @Binding var selection: CheckpointFilter

    var body: some View {
        HStack(spacing: 4) {
            ForEach(CheckpointFilter.allCases) { filter in
                Button {
                    selection = filter
                } label: {
                    Text(filter.title)
                        .font(PSFont.semibold(11))
                        .foregroundStyle(
                            selection == filter
                                ? PSColor.electricBlue
                                : Color.white.opacity(0.50)
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            selection == filter
                                ? PSColor.electricBlue.opacity(0.12)
                                : Color.white.opacity(0.04),
                            in: Capsule()
                        )
                }
                .buttonStyle(PSPressStyle())
            }
        }
    }
}

private struct SavedCheckpointCard: View {
    let checkpoint: CheckpointItem
    let onToggleComplete: () -> Void
    let onDetail: () -> Void

    var body: some View {
        PSGlassCard(variant: .primary, padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onToggleComplete) {
                    Image(systemName: checkpoint.completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(checkpoint.completed ? PSColor.emerald : Color.white.opacity(0.45))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(PSPressStyle())

                Button(action: onDetail) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(checkpoint.text)
                            .font(PSFont.semibold(13))
                            .foregroundStyle(checkpoint.completed ? Color.white.opacity(0.45) : PSColor.textPrimary)
                            .strikethrough(checkpoint.completed, color: Color.white.opacity(0.40))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 6) {
                            policyBadge(checkpoint.linkedPolicyTitle, color: policyColor(for: checkpoint.linkedPolicyId))

                            if checkpoint.alertOn {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(PSColor.electricBlue.opacity(0.70))
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct EmptyCheckpointState: View {
    var body: some View {
        PSGlassCard(variant: .secondary, padding: 18) {
            Text("아직 표시할 항목이 없어요.")
                .font(PSFont.body(13))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct CheckpointTagFlow<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) {
                content
            }

            VStack(alignment: .leading, spacing: spacing) {
                content
            }
        }
    }
}

@ViewBuilder
func sectionTitle(_ text: String) -> some View {
    Text(text)
        .font(PSFont.semibold(16))
        .foregroundStyle(PSColor.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
}

@ViewBuilder
func policyBadge(_ text: String, color: Color) -> some View {
    Text(text)
        .font(PSFont.caption(10))
        .foregroundStyle(color)
        .lineLimit(1)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.10), in: Capsule())
}

@ViewBuilder
func importanceBadge(_ importance: PSImportance) -> some View {
    let color = importance == .high ? PSColor.red : importance == .medium ? PSColor.yellow : PSColor.gray

    Text(importance.rawValue)
        .font(PSFont.caption(10))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.10), in: Capsule())
}

@ViewBuilder
func assetTag(_ text: String, color: Color) -> some View {
    Text(text)
        .font(PSFont.caption(10))
        .foregroundStyle(color.opacity(0.90))
        .lineLimit(1)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.10), in: Capsule())
}

func policyColor(for policyId: Int) -> Color {
    switch policyId {
    case 1: return PSColor.electricBlue
    case 2: return PSColor.purple
    case 3: return PSColor.yellow
    case 4: return PSColor.emerald
    default: return PSColor.gray
    }
}
