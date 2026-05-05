import SwiftUI

struct CheckpointView: View {
    @StateObject private var viewModel: CheckpointViewModel

    init(viewModel: CheckpointViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? CheckpointViewModel())
    }

    var body: some View {
        ZStack {
            checkpointBackground

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: PSSpacing.sectionGap) {
                    CheckpointHeaderView(summary: viewModel.headerSummary)

                    WeeklyPolicyAccordionSection(
                        policyEvents: viewModel.policyEvents,
                        isExpanded: viewModel.isExpanded,
                        onToggle: viewModel.togglePolicy,
                        onCheckpointTap: viewModel.presentDetail,
                        decisionsFor: viewModel.decisions(for:)
                    )

                    SavedCheckpointsSection(
                        selectedFilter: $viewModel.selectedFilter,
                        checkpoints: viewModel.filteredCheckpoints,
                        onToggleComplete: viewModel.toggleCheckpointCompletion,
                        onDetail: viewModel.presentDetail
                    )
                }
                .padding(.horizontal, PSSpacing.pagePad)
                .padding(.top, 8)
                .padding(.bottom, 110)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $viewModel.detailCheckpoint) { checkpoint in
            CheckpointDetailSheet(
                checkpoint: checkpoint,
                policy: viewModel.policy(for: checkpoint),
                decisions: viewModel.decisions(for: checkpoint.linkedPolicyId),
                onToggleAlert: { viewModel.toggleCheckpointAlert(checkpoint) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.clear)
            .presentationCornerRadius(28)
        }
    }

    private var checkpointBackground: some View {
        ZStack {
            Color(hex: "0A0E27").ignoresSafeArea()
            Circle()
                .fill(PSColor.electricBlue.opacity(0.12))
                .frame(width: 320)
                .blur(radius: 130)
                .offset(x: -150, y: -300)
            Circle()
                .fill(PSColor.emerald.opacity(0.08))
                .frame(width: 260)
                .blur(radius: 120)
                .offset(x: 160, y: -110)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    CheckpointView()
}
