import SwiftUI

/// Edit the onboarding answers. Changes save as you go.
struct AccountView: View {
    let user: User
    @ObservedObject private var loc = Localizer.shared

    @State private var name: String = ""
    @State private var age: String = ""
    @State private var sex: BiologicalSex = .preferNotToSay
    @State private var activity: ActivityLevel = .notSet

    var body: some View {
        Form {
            Section {
                TextField(loc.t("First name"), text: $name)
                    .textInputAutocapitalization(.words)
                    .onChange(of: name) { _, new in user.name = new.trimmingCharacters(in: .whitespacesAndNewlines) }
                HStack {
                    Text(loc.t("Age"))
                    Spacer()
                    TextField(loc.t("Not set"), text: $age)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onChange(of: age) { _, new in
                            let digits = String(new.filter(\.isNumber).prefix(3))
                            if digits != new { age = digits }
                            user.age = Int(digits).flatMap { (5...120).contains($0) ? $0 : nil }
                        }
                }
                Picker(loc.t("Sex"), selection: $sex) {
                    ForEach(BiologicalSex.allCases, id: \.self) { Text(loc.t($0.rawValue)).tag($0) }
                }
                .onChange(of: sex) { _, new in user.sex = new }
                Picker(loc.t("Exercise"), selection: $activity) {
                    ForEach(ActivityLevel.allCases, id: \.self) { Text(loc.t($0.title)).tag($0) }
                }
                .onChange(of: activity) { _, new in user.activityLevel = new }
            } footer: {
                Text(loc.t("These answers give your readings and insights context. They stay on this phone."))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Tokens.Colors.adaptiveBackground)
        .navigationTitle(loc.t("Account"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = user.name
            age = user.age.map(String.init) ?? ""
            sex = user.sex
            activity = user.activityLevel
        }
    }
}
