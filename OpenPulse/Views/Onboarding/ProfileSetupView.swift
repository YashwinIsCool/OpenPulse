import SwiftUI
import SwiftData

/// A short onboarding quiz, one question per screen. The answers give results and
/// insights context (and seed the personal heart model) from day one. Every
/// question can be skipped, and everything stays on the device.
struct ProfileSetupView: View {
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @Query private var users: [User]
    @StateObject private var permissions = PermissionsManager()
    @ObservedObject private var loc = Localizer.shared

    private enum Question: Int, CaseIterable {
        case name, age, sex, activity, reminders
    }

    @State private var question: Question = .name
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var sex: BiologicalSex?
    @State private var activity: ActivityLevel?
    @State private var remindersOn: Bool?
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.top, Tokens.Spacing.sm)

            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.xxl) {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                        Text(loc.t(title))
                            .font(Tokens.Fonts.screenTitle)
                            .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                        Text(loc.t(why))
                            .font(Tokens.Fonts.bodyText)
                            .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    answers
                }
                .padding(.horizontal, Tokens.Spacing.xl)
                .padding(.top, Tokens.Spacing.xxl)
            }
            .scrollDismissesKeyboard(.interactively)

            PrimaryButton(title: loc.t(question == .reminders ? "Finish" : "Continue")) {
                advance()
            }
            .padding(.horizontal, Tokens.Spacing.xl)
            .padding(.bottom, Tokens.Spacing.xl)
        }
        .animation(.easeInOut(duration: 0.2), value: question)
        .onAppear { fieldFocused = true }
        .onChange(of: question) { _, new in
            // Focus after the transition settles, or the keyboard won't attach.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                fieldFocused = new == .name || new == .age
            }
        }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack(spacing: Tokens.Spacing.md) {
            Button {
                if let previous = Question(rawValue: question.rawValue - 1) { question = previous }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                    .frame(width: 32, height: 32)
            }
            .opacity(question == .name ? 0 : 1)
            .disabled(question == .name)
            .accessibilityLabel("Back")

            HStack(spacing: 4) {
                ForEach(Question.allCases, id: \.self) { q in
                    Capsule()
                        .fill(q.rawValue <= question.rawValue ? Tokens.Colors.ink : Tokens.Colors.adaptiveBorder)
                        .frame(height: 4)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Question \(question.rawValue + 1) of \(Question.allCases.count)")

            Button(loc.t("Skip")) { skip() }
                .font(.body.weight(.medium))
                .foregroundStyle(Tokens.Colors.adaptiveTextSecondary)
                .opacity(question == .reminders ? 0 : 1)
                .disabled(question == .reminders)
        }
    }

    // MARK: - Questions

    private var title: String {
        switch question {
        case .name: return "What should we call you?"
        case .age: return "How old are you?"
        case .sex: return "What's your sex?"
        case .activity: return "How often do you exercise?"
        case .reminders: return "Want a daily reminder?"
        }
    }

    private var why: String {
        switch question {
        case .name: return "Just a first name or nickname. Everything you answer stays on this phone."
        case .age: return "Typical heart rates change with age, so this helps put your readings in context."
        case .sex: return "On average, resting heart rates differ a little between women and men."
        case .activity: return "Active people often have a lower resting heart rate. This helps us understand yours."
        case .reminders: return "A gentle nudge each morning to check your heart. You can change this any time."
        }
    }

    @ViewBuilder
    private var answers: some View {
        switch question {
        case .name:
            TextField(loc.t("First name"), text: $name)
                .font(.system(.title2))
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .focused($fieldFocused)
                .onSubmit { advance() }
                .padding(.vertical, Tokens.Spacing.md)
                .overlay(alignment: .bottom) { Rectangle().fill(Tokens.Colors.adaptiveBorder).frame(height: 1) }

        case .age:
            HStack(alignment: .lastTextBaseline, spacing: Tokens.Spacing.sm) {
                TextField("", text: $age, prompt: Text("0").foregroundStyle(Tokens.Colors.adaptiveTextQuaternary))
                    .font(.system(size: 48, weight: .semibold))
                    .keyboardType(.numberPad)
                    .focused($fieldFocused)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 96)
                    .onChange(of: age) { _, new in age = String(new.filter(\.isNumber).prefix(3)) }
                Text(loc.t("years"))
                    .font(Tokens.Fonts.headline)
                    .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
            }
            .padding(.vertical, Tokens.Spacing.sm)
            .overlay(alignment: .bottom) { Rectangle().fill(Tokens.Colors.adaptiveBorder).frame(height: 1) }

        case .sex:
            VStack(spacing: Tokens.Spacing.sm) {
                ForEach(BiologicalSex.allCases, id: \.self) { option in
                    OptionRow(title: loc.t(option.rawValue), detail: nil, isSelected: sex == option) {
                        sex = option
                    }
                }
            }

        case .activity:
            VStack(spacing: Tokens.Spacing.sm) {
                ForEach(ActivityLevel.answerable, id: \.self) { option in
                    OptionRow(title: loc.t(option.title), detail: option.detail.map(loc.t), isSelected: activity == option) {
                        activity = option
                    }
                }
            }

        case .reminders:
            VStack(spacing: Tokens.Spacing.sm) {
                OptionRow(title: loc.t("Yes, remind me"), detail: nil, isSelected: remindersOn == true) {
                    remindersOn = true
                }
                OptionRow(title: loc.t("No thanks"), detail: nil, isSelected: remindersOn == false) {
                    remindersOn = false
                }
            }
        }
    }

    // MARK: - Flow

    private func skip() {
        switch question {
        case .name: name = ""
        case .age: age = ""
        case .sex: sex = nil
        case .activity: activity = nil
        case .reminders: break
        }
        advance()
    }

    private func advance() {
        if let next = Question(rawValue: question.rawValue + 1) {
            question = next
        } else {
            completeSetup()
        }
    }

    private func completeSetup() {
        let user = users.first ?? {
            let newUser = User()
            modelContext.insert(newUser)
            return newUser
        }()

        user.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        user.age = Int(age).flatMap { (5...120).contains($0) ? $0 : nil }
        user.sex = sex ?? .preferNotToSay
        user.activityLevel = activity ?? .notSet

        let wantsReminders = remindersOn ?? false
        settings.notificationsEnabled = wantsReminders
        if wantsReminders {
            permissions.requestNotifications { granted in
                if granted {
                    NotificationManager.shared.scheduleAllNotifications(settings: settings)
                }
            }
        }

        onComplete()
    }
}

/// A full-width answer row: tap to pick. The picked row gets an ink outline and a
/// checkmark, so the choice is clear without relying on color.
struct OptionRow: View {
    let title: String
    let detail: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Tokens.Fonts.bodyText.weight(.medium))
                        .foregroundStyle(Tokens.Colors.adaptiveTextPrimary)
                    if let detail {
                        Text(detail)
                            .font(Tokens.Fonts.secondaryText)
                            .foregroundStyle(Tokens.Colors.adaptiveTextTertiary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Tokens.Colors.ink : Tokens.Colors.adaptiveBorder)
            }
            .padding(.horizontal, Tokens.Spacing.lg)
            .padding(.vertical, 16)
            .background(Tokens.Colors.adaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                    .stroke(isSelected ? Tokens.Colors.ink : Tokens.Colors.adaptiveBorder, lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
