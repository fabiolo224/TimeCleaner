import Foundation
import AppKit
import UserNotifications
import ServiceManagement
import SwiftUI

// MARK: - AppSettings

class AppSettings: ObservableObject {
    private let ud = UserDefaults.standard

    @Published var weeklyNotification: Bool {
        didSet {
            ud.set(weeklyNotification, forKey: "weeklyNotification")
            if weeklyNotification { requestAndScheduleWeekly() } else { cancelWeekly() }
        }
    }
    @Published var autoScanOnOpen: Bool {
        didSet { ud.set(autoScanOnOpen, forKey: "autoScanOnOpen") }
    }
    @Published var minFileSizeMB: Double {
        didSet { ud.set(minFileSizeMB, forKey: "minFileSizeMB") }
    }
    @Published var excludedFolders: [String] {
        didSet { ud.set(excludedFolders, forKey: "excludedFolders") }
    }
    @Published var suggestionThresholdMonths: Int {
        didSet { ud.set(suggestionThresholdMonths, forKey: "suggestionThresholdMonths") }
    }

    init() {
        let ud = UserDefaults.standard
        if ud.object(forKey: "weeklyNotification")        == nil { ud.set(true,     forKey: "weeklyNotification") }
        if ud.object(forKey: "autoScanOnOpen")            == nil { ud.set(true,     forKey: "autoScanOnOpen") }
        if ud.object(forKey: "minFileSizeMB")             == nil { ud.set(10.0,     forKey: "minFileSizeMB") }
        if ud.object(forKey: "excludedFolders")           == nil { ud.set([String](), forKey: "excludedFolders") }
        if ud.object(forKey: "suggestionThresholdMonths") == nil { ud.set(3,        forKey: "suggestionThresholdMonths") }

        weeklyNotification        = ud.bool(forKey: "weeklyNotification")
        autoScanOnOpen            = ud.bool(forKey: "autoScanOnOpen")
        let saved                 = ud.double(forKey: "minFileSizeMB")
        minFileSizeMB             = saved > 0 ? saved : 10
        excludedFolders           = ud.stringArray(forKey: "excludedFolders") ?? []
        let savedMonths           = ud.integer(forKey: "suggestionThresholdMonths")
        suggestionThresholdMonths = savedMonths > 0 ? savedMonths : 3

        try? SMAppService.mainApp.register()
        if weeklyNotification { requestAndScheduleWeekly() }
    }

    // MARK: - Weekly notification

    func requestAndScheduleWeekly() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, _ in
                guard granted else { return }
                self.scheduleWeeklyStatic()
            }
    }

    func scheduleWeeklyWithData(unusedBytes: Int64) {
        guard weeklyNotification else { return }
        let formatted = ByteCountFormatter.string(fromByteCount: unusedBytes, countStyle: .file)
        let content = UNMutableNotificationContent()
        content.title = "TimeCleaner"
        content.body = isItalian
            ? "Hai \(formatted) di file inutilizzati da recuperare."
            : "You have \(formatted) of unused files to recover."
        content.sound = .default
        replaceWeekly(content)
    }

    private func scheduleWeeklyStatic() {
        let content = UNMutableNotificationContent()
        content.title = "TimeCleaner"
        content.body = isItalian
            ? "Hai controllato i file inutilizzati questa settimana?"
            : "Have you checked your unused files this week?"
        content.sound = .default
        replaceWeekly(content)
    }

    private func replaceWeekly(_ content: UNMutableNotificationContent) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["tc-weekly"])
        var dc = DateComponents(); dc.weekday = 2; dc.hour = 10
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "tc-weekly", content: content, trigger: trigger)
        )
    }

    func cancelWeekly() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["tc-weekly"])
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(L("Impostazioni", "Settings")).font(.headline)
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16)).foregroundColor(.secondary)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 14)

            Divider()

            ScrollView {
                VStack(spacing: 0) {

                    // 1. Notifica settimanale
                    SettingRow(icon: "bell.badge", iconColor: .red,
                               title: L("Notifica settimanale", "Weekly reminder"),
                               subtitle: L("Ti avvisa ogni lunedì con lo spazio recuperabile trovato",
                                           "Notifies you every Monday with the recoverable space found")) {
                        Toggle("", isOn: $settings.weeklyNotification).labelsHidden()
                    }
                    Divider().padding(.leading, 56)

                    // 2. Scansione automatica
                    SettingRow(icon: "arrow.clockwise.circle", iconColor: .accentColor,
                               title: L("Scansione automatica all'avvio", "Auto-scan on open"),
                               subtitle: L("Parte da sola quando apri il popover dalla barra",
                                           "Starts automatically when you open the popover")) {
                        Toggle("", isOn: $settings.autoScanOnOpen).labelsHidden()
                    }
                    Divider().padding(.leading, 56)

                    // 3. Dimensione minima file
                    SettingRow(icon: "doc.badge.gearshape", iconColor: .orange,
                               title: L("Dimensione minima file", "Minimum file size"),
                               subtitle: L("Mostra solo i file più grandi di questa soglia",
                                           "Only shows files larger than this threshold")) {
                        Picker("", selection: $settings.minFileSizeMB) {
                            Text("1 MB").tag(1.0)
                            Text("10 MB").tag(10.0)
                            Text("50 MB").tag(50.0)
                            Text("100 MB").tag(100.0)
                            Text("500 MB").tag(500.0)
                        }.pickerStyle(.menu).frame(width: 90)
                    }
                    Divider().padding(.leading, 56)

                    // 4. Soglia di suggerimento
                    SettingRow(icon: "hand.thumbsup", iconColor: .indigo,
                               title: L("Soglia di suggerimento", "Suggestion threshold"),
                               subtitle: L("Mesi di inattività prima che un elemento venga segnalato",
                                           "Months of inactivity before an item is flagged")) {
                        Picker("", selection: $settings.suggestionThresholdMonths) {
                            Text(L("1 mese", "1 month")).tag(1)
                            Text(L("3 mesi", "3 months")).tag(3)
                            Text(L("6 mesi", "6 months")).tag(6)
                            Text(L("12 mesi", "12 months")).tag(12)
                        }.pickerStyle(.menu).frame(width: 110)
                    }
                    Divider().padding(.leading, 56)

                    // 5. Cartelle escluse
                    ExcludedFoldersRow()

                }
            }

            Spacer(minLength: 0)
        }
        .frame(width: 440, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Excluded folders row

private struct ExcludedFoldersRow: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.brown)
                        .frame(width: 32, height: 32)
                    Image(systemName: "folder.badge.minus")
                        .font(.system(size: 14)).foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Cartelle escluse", "Excluded folders"))
                        .font(.system(size: 13, weight: .medium))
                    Text(L("Queste cartelle non verranno mai scansionate",
                           "These folders will never be scanned"))
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button(action: addFolder) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.accentColor)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 24).padding(.top, 10)

            if settings.excludedFolders.isEmpty {
                Text(L("Nessuna cartella esclusa", "No excluded folders"))
                    .font(.caption).foregroundColor(.secondary)
                    .padding(.leading, 70).padding(.bottom, 10)
            } else {
                VStack(spacing: 0) {
                    ForEach(settings.excludedFolders, id: \.self) { path in
                        HStack(spacing: 8) {
                            Image(systemName: "folder").foregroundColor(.secondary).font(.caption)
                            Text((path as NSString).lastPathComponent)
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .help(path)
                            Spacer()
                            Button(action: { settings.excludedFolders.removeAll { $0 == path } }) {
                                Image(systemName: "minus.circle").foregroundColor(.red).font(.caption)
                            }.buttonStyle(.plain)
                        }
                        .padding(.horizontal, 70).padding(.vertical, 4)
                    }
                }
                .padding(.bottom, 10)
            }
        }
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles      = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = L("Escludi", "Exclude")
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let path = url.path
            if !settings.excludedFolders.contains(path) {
                settings.excludedFolders.append(path)
            }
        }
    }
}

// MARK: - Shared row layout

struct SettingRow<Control: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let control: () -> Control

    init(icon: String, iconColor: Color, title: String, subtitle: String,
         @ViewBuilder control: @escaping () -> Control) {
        self.icon = icon; self.iconColor = iconColor
        self.title = title; self.subtitle = subtitle; self.control = control
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            control()
        }
        .padding(.horizontal, 24).padding(.vertical, 10)
    }
}
