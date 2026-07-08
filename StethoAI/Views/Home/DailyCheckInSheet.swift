import SwiftUI

/// The values captured in a daily check-in. Everything is optional so the user can
/// answer only what they want; the more they log, the smarter their insights get.
struct CheckInData {
    var sleepHours: Double?
    var caffeineCups: Int?
    var exerciseMinutes: Int?
    var stressLevel: Int?
    var mood: Int?
}

struct DailyCheckInSheet: View {
    var initial: CheckInData = CheckInData()
    let onSave: (CheckInData) -> Void
    @Environment(\.dismiss) private var dismiss

    private let sleepValues: [Double] = [4, 5, 6, 7, 8, 9]
    private let sleepLabels = ["<5", "5", "6", "7", "8", "9+"]
    private let caffeineValues = [0, 1, 2, 3]
    private let caffeineLabels = ["None", "1", "2", "3+"]
    private let exerciseValues = [0, 15, 40, 75]
    private let exerciseLabels = ["None", "Light", "Moder.", "Intense"]

    @State private var sleepIndex: Int?
    @State private var caffeineIndex: Int?
    @State private var exerciseIndex: Int?
    @State private var stress: Int?
    @State private var mood: Int?

    init(initial: CheckInData = CheckInData(), onSave: @escaping (CheckInData) -> Void) {
        self.initial = initial
        self.onSave = onSave
        _sleepIndex = State(initialValue: initial.sleepHours.flatMap { h in [4.0, 5, 6, 7, 8, 9].firstIndex(where: { abs($0 - h) < 0.6 }) })
        _caffeineIndex = State(initialValue: initial.caffeineCups.flatMap { [0, 1, 2, 3].firstIndex(of: $0) })
        _exerciseIndex = State(initialValue: initial.exerciseMinutes.flatMap { [0, 15, 40, 75].firstIndex(of: $0) })
        _stress = State(initialValue: initial.stressLevel)
        _mood = State(initialValue: initial.mood)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.xl) {
                    Text("A quick check-in helps StethoAI learn what moves your heart rate. Log what you can — skip the rest.")
                        .font(Tokens.Fonts.body)
                        .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)

                    section("How many hours did you sleep?") {
                        PillRow(labels: sleepLabels, selectedIndex: $sleepIndex)
                    }
                    section("Caffeinated drinks today?") {
                        PillRow(labels: caffeineLabels, selectedIndex: $caffeineIndex)
                    }
                    section("Did you exercise today?") {
                        PillRow(labels: exerciseLabels, selectedIndex: $exerciseIndex)
                    }
                    section("How stressed do you feel?") {
                        ScaleRow(range: 1...5, lowLabel: "Calm", highLabel: "Stressed", selected: $stress)
                    }
                    section("How's your mood?") {
                        ScaleRow(range: 1...5, lowLabel: "Low", highLabel: "Great", selected: $mood)
                    }
                }
                .padding(Tokens.Spacing.lg)
            }
            .background(Tokens.Colors.adaptiveBackground)
            .navigationTitle("Daily check-in")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Save check-in", icon: "checkmark") {
                    onSave(CheckInData(
                        sleepHours: sleepIndex.map { sleepValues[$0] },
                        caffeineCups: caffeineIndex.map { caffeineValues[$0] },
                        exerciseMinutes: exerciseIndex.map { exerciseValues[$0] },
                        stressLevel: stress,
                        mood: mood
                    ))
                }
                .padding(.horizontal, Tokens.Spacing.lg)
                .padding(.vertical, Tokens.Spacing.md)
                .background(Tokens.Colors.adaptiveBackground)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            Text(title)
                .font(Tokens.Fonts.cardTitle)
                .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
            content()
        }
    }
}

/// A horizontal row of selectable pills.
private struct PillRow: View {
    let labels: [String]
    @Binding var selectedIndex: Int?

    var body: some View {
        HStack(spacing: Tokens.Spacing.sm) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                let isSelected = selectedIndex == index
                Text(label)
                    .font(Tokens.Fonts.body)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(isSelected ? .white : Tokens.Colors.primaryRed)
                    .background(isSelected ? Tokens.Colors.primaryRed : Tokens.Colors.adaptiveSoftRedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.12)) {
                            selectedIndex = isSelected ? nil : index
                        }
                    }
            }
        }
    }
}

/// A 1...5 circular scale with end labels.
private struct ScaleRow: View {
    let range: ClosedRange<Int>
    let lowLabel: String
    let highLabel: String
    @Binding var selected: Int?

    var body: some View {
        VStack(spacing: Tokens.Spacing.xs) {
            HStack(spacing: Tokens.Spacing.sm) {
                ForEach(Array(range), id: \.self) { value in
                    let isSelected = selected == value
                    Text("\(value)")
                        .font(Tokens.Fonts.cardTitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(isSelected ? .white : Tokens.Colors.primaryRed)
                        .background(isSelected ? Tokens.Colors.primaryRed : Tokens.Colors.adaptiveSoftRedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.12)) {
                                selected = isSelected ? nil : value
                            }
                        }
                }
            }
            HStack {
                Text(lowLabel)
                Spacer()
                Text(highLabel)
            }
            .font(Tokens.Fonts.caption)
            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
        }
    }
}
