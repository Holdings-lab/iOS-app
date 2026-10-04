import SwiftUI

// MARK: - Big single-select choice card

struct ChoiceCard: View {
    let isOn: Bool
    let icon: String
    let title: String
    var subtitle: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Text(icon)
                    .font(.system(size: 20))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.pretendard(14.5, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.pretendard(12.5, weight: .regular))
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Circle()
                    .fill(isOn ? Color.brand : Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay {
                        Circle().stroke(isOn ? Color.brand : Color.hairline, lineWidth: 1.5)
                        if isOn {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                    }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isOn ? Color.brandTintBg : Color.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isOn ? Color.brand : Color.hairline, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact period row

struct PeriodRow: View {
    let isOn: Bool
    let title: String
    var subtitle: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.pretendard(12, weight: .regular))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Circle()
                    .stroke(isOn ? Color.brand : Color.hairline, lineWidth: isOn ? 5 : 1.5)
                    .frame(width: 18, height: 18)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(isOn ? Color.brandTintBg : Color.elevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isOn ? Color.brand : Color.hairline, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Multi-select chip grid

struct MultiSelectGridItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
}

struct MultiSelectGrid: View {
    let items: [MultiSelectGridItem]
    let selected: Set<String>
    let max: Int?
    let onToggle: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items) { item in
                let isOn = selected.contains(item.id)
                let isDisabled = !isOn && max.map { selected.count >= $0 } == true

                Button {
                    guard !isDisabled else { return }
                    onToggle(item.id)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        if !item.icon.isEmpty {
                            Text(item.icon)
                                .font(.system(size: 18))
                        }

                        Text(item.title)
                            .font(.pretendard(13.5, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        Text(item.subtitle)
                            .font(.pretendard(11.5, weight: .regular))
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(isOn ? Color.brandTintBg : Color.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isOn ? Color.brand : Color.hairline, lineWidth: 1.5)
                    }
                    .overlay(alignment: .topTrailing) {
                        if isOn {
                            Circle()
                                .fill(Color.brand)
                                .frame(width: 18, height: 18)
                                .overlay {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color.white)
                                }
                                .padding(10)
                        }
                    }
                    .opacity(isDisabled ? 0.4 : 1)
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
            }
        }
        .padding(.top, 12)
    }
}

struct SettingsCounterPill: View {
    let count: Int
    let max: Int

    var body: some View {
        Text("\(count)/\(max)")
            .font(.pretendard(12, weight: .bold))
            .foregroundStyle(Color.brand)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(Color.brandTintBg, in: Capsule())
    }
}
