import SwiftUI
import AppKit

// MARK: - Root

struct ContentView: View {
    @State private var tab: Tab = .apps
    @State private var showUninstallConfirm = false
    @State private var showSettings = false
    @EnvironmentObject var updater: UpdateChecker
    @EnvironmentObject var settings: AppSettings
    enum Tab { case apps, files }

    var body: some View {
        VStack(spacing: 0) {
            // Update banner
            if updater.updateAvailable {
                UpdateBanner(updater: updater)
            }

            HStack(spacing: 0) {
                TabButton(title: L("Applicazioni", "Applications"), icon: "app.badge", selected: tab == .apps)  { tab = .apps }
                TabButton(title: L("File", "Files"),                icon: "doc.fill",  selected: tab == .files) { tab = .files }
                Spacer()
                Menu {
                    Button(action: { showSettings = true }) {
                        Label(L("Impostazioni", "Settings"), systemImage: "gearshape")
                    }
                    Divider()
                    Button(role: .destructive, action: { showUninstallConfirm = true }) {
                        Label(L("Disinstalla TimeCleaner", "Uninstall TimeCleaner"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 28)
                .padding(.trailing, 12)
            }
            .padding(.horizontal, 16).padding(.top, 10)
            .background(Color(NSColor.windowBackgroundColor))
            .alert(L("Disinstallare TimeCleaner?", "Uninstall TimeCleaner?"), isPresented: $showUninstallConfirm) {
                Button(L("Disinstalla", "Uninstall"), role: .destructive) { uninstall() }
                Button(L("Annulla", "Cancel"), role: .cancel) {}
            } message: {
                Text(L("L'app verrà rimossa da /Applications e non si avvierà più al login.",
                       "The app will be removed from /Applications and will no longer launch at login."))
            }

            Divider()

            if tab == .apps { AppsView() } else { FilesView() }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(settings)
        }
    }
}

// MARK: - Update banner

struct UpdateBanner: View {
    @ObservedObject var updater: UpdateChecker

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.white)
            Text(L("Aggiornamento disponibile: v\(updater.latestVersion)",
                   "Update available: v\(updater.latestVersion)"))
                .font(.callout).bold().foregroundColor(.white)
            Spacer()
            if updater.isDownloading {
                ProgressView(value: updater.downloadProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 100)
                    .tint(.white)
                Text("\(Int(updater.downloadProgress * 100))%")
                    .font(.caption).foregroundColor(.white)
            } else {
                Button(L("Aggiorna e riavvia", "Update & restart")) {
                    updater.downloadAndInstall()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .foregroundColor(.white).font(.callout).bold()
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.accentColor)
    }
}

struct TabButton: View {
    let title: String; let icon: String; let selected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12))
                Text(title).font(.system(size: 13, weight: selected ? .semibold : .regular))
            }
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(selected ? Color.accentColor.opacity(0.12) : Color.clear)
            .foregroundColor(selected ? .accentColor : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }.buttonStyle(.plain)
    }
}

// MARK: - Apps tab

struct AppsView: View {
    @StateObject private var scanner = AppScanner()
    @EnvironmentObject var settings: AppSettings
    @State private var selection = Set<UUID>()
    @State private var showBulkConfirm  = false
    @State private var showSingleConfirm = false
    @State private var singleTarget: AppInfo?

    private var selectedApps: [AppInfo] {
        scanner.filteredApps.filter { selection.contains($0.id) }
    }
    private var selectedSize: Int64 {
        selectedApps.reduce(0) { $0 + $1.size }
    }
    private var allChecked: Bool {
        !scanner.filteredApps.isEmpty && scanner.filteredApps.allSatisfy { selection.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                if scanner.apps.isEmpty {
                    Text(L("Scansiona le applicazioni installate", "Scan installed applications"))
                        .font(.caption).foregroundColor(.secondary)
                } else {
                    Text("\(scanner.apps.count) app · \(ByteCountFormatter.string(fromByteCount: scanner.totalSize, countStyle: .file))")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if scanner.isScanning {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.65)
                        Text(scanner.scanProgress).font(.caption).foregroundColor(.secondary).lineLimit(1)
                    }
                }
                Menu {
                    Button {
                        selection.removeAll()
                        scanner.filterMode = .all
                        scanner.sortMode = .riskScore
                        scanner.scan()
                    } label: { Label(L("Tutti", "All"), systemImage: "square.grid.2x2") }
                    Button {
                        selection.removeAll()
                        scanner.filterMode = .unused90
                        scanner.sortMode = .lastUsed
                        scanner.scan()
                    } label: { Label(L("Non usati 3+ mesi", "Unused 3+ months"), systemImage: "clock") }
                    Button {
                        selection.removeAll()
                        scanner.filterMode = .unused180
                        scanner.sortMode = .lastUsed
                        scanner.scan()
                    } label: { Label(L("Non usati 6+ mesi", "Unused 6+ months"), systemImage: "clock.badge.xmark") }
                    Button {
                        selection.removeAll()
                        scanner.filterMode = .all
                        scanner.sortMode = .size
                        scanner.scan()
                    } label: { Label(L("Per dimensione", "By size"), systemImage: "arrow.up.arrow.down") }
                } label: {
                    Label(L("Scansiona", "Scan"), systemImage: "arrow.clockwise")
                }
                .disabled(scanner.isScanning)
                .menuStyle(.borderlessButton)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .opacity(scanner.isScanning ? 0.5 : 1.0)
            }
            .padding(.horizontal, 20).padding(.vertical, 10)

            if !selection.isEmpty {
                SelectionBar(
                    count: selection.count,
                    size: selectedSize,
                    onClear: { selection.removeAll() },
                    onDelete: { showBulkConfirm = true }
                )
            }

            Divider()

            if scanner.apps.isEmpty && !scanner.isScanning {
                EmptyState(icon: "app.badge", text: L("Premi Scansiona per analizzare le app", "Press Scan to analyse apps"))
            } else {
                HStack(spacing: 0) {
                    Toggle("", isOn: Binding(
                        get: { allChecked },
                        set: { v in
                            if v { scanner.filteredApps.forEach { selection.insert($0.id) } }
                            else { selection.removeAll() }
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .frame(width: 28)
                    .help(allChecked ? L("Deseleziona tutto", "Deselect all") : L("Seleziona tutto", "Select all"))

                    Text(L("Applicazione", "Application")).frame(maxWidth: .infinity, alignment: .leading)
                    Text(L("Dimensione", "Size")).frame(width: 110, alignment: .trailing)
                    Text(L("Ultimo utilizzo", "Last used")).frame(width: 140, alignment: .trailing)
                    Text(L("Suggerimento", "Suggestion")).frame(width: 180, alignment: .center)
                    Text(L("Azioni", "Actions")).frame(width: 60, alignment: .center)
                }
                .font(.caption).foregroundColor(.secondary)
                .padding(.horizontal, 20).padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))

                Divider()
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(scanner.filteredApps) { app in
                            AppRow(
                                app: app,
                                isChecked: selection.contains(app.id),
                                onToggle: {
                                    if selection.contains(app.id) { selection.remove(app.id) }
                                    else { selection.insert(app.id) }
                                },
                                onReveal: { scanner.revealInFinder(app) },
                                onDelete: { singleTarget = app; showSingleConfirm = true }
                            )
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }

            if !scanner.apps.isEmpty {
                FooterBar {
                    let high = scanner.filteredApps.filter { $0.riskScore >= 70 }
                    let sz   = high.reduce(Int64(0)) { $0 + $1.size }
                    Text(L(
                        "\(high.count) app consigliate · risparmio potenziale: \(ByteCountFormatter.string(fromByteCount: sz, countStyle: .file))",
                        "\(high.count) apps suggested · potential saving: \(ByteCountFormatter.string(fromByteCount: sz, countStyle: .file))"
                    )).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            if settings.autoScanOnOpen && scanner.apps.isEmpty { scanner.scan() }
        }
        .onChange(of: scanner.isScanning) { _, scanning in
            guard !scanning && !scanner.apps.isEmpty && settings.weeklyNotification else { return }
            let t = settings.suggestionThresholdMonths * 30
            let bytes = scanner.apps
                .filter { $0.unusedDays > t }
                .reduce(Int64(0)) { $0 + $1.size }
            if bytes > 0 { settings.scheduleWeeklyWithData(unusedBytes: bytes) }
        }
        .alert(L("Eliminare \(selection.count) app?", "Delete \(selection.count) apps?"), isPresented: $showBulkConfirm) {
            Button(L("Sposta nel Cestino", "Move to Trash"), role: .destructive) {
                let toDelete = selectedApps
                selection.removeAll()
                toDelete.forEach { scanner.moveToTrash($0) }
            }
            Button(L("Annulla", "Cancel"), role: .cancel) {}
        } message: {
            Text(L(
                "Verranno spostate nel Cestino \(selection.count) app (\(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))). Potrai recuperarle prima di svuotarlo.",
                "\(selection.count) apps (\(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))) will be moved to Trash. You can recover them before emptying it."
            ))
        }
        .alert(L("Eliminare \"\(singleTarget?.name ?? "")\"?", "Delete \"\(singleTarget?.name ?? "")\"?"), isPresented: $showSingleConfirm) {
            Button(L("Sposta nel Cestino", "Move to Trash"), role: .destructive) {
                if let a = singleTarget { selection.remove(a.id); scanner.moveToTrash(a) }
            }
            Button(L("Annulla", "Cancel"), role: .cancel) {}
        } message: {
            Text(L("L'app verrà spostata nel Cestino. Potrai recuperarla prima di svuotarlo.",
                   "The app will be moved to Trash. You can recover it before emptying it."))
        }
    }
}

// MARK: - Files tab

struct FilesView: View {
    @StateObject private var scanner = FileScanner()
    @EnvironmentObject var settings: AppSettings
    @State private var selection = Set<UUID>()
    @State private var showBulkConfirm   = false
    @State private var showSingleConfirm = false
    @State private var singleTarget: FileItem?

    private var selectedItems: [FileItem] {
        scanner.filteredFiles.filter { selection.contains($0.id) }
    }
    private var selectedSize: Int64 { selectedItems.reduce(0) { $0 + $1.size } }
    private var allChecked: Bool {
        !scanner.filteredFiles.isEmpty && scanner.filteredFiles.allSatisfy { selection.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                if scanner.files.isEmpty {
                    Text(L("Scansiona Download, Documenti, Cache e altro", "Scan Downloads, Documents, Cache and more"))
                        .font(.caption).foregroundColor(.secondary)
                } else {
                    Text("\(scanner.files.count) \(L("file", "files")) · \(ByteCountFormatter.string(fromByteCount: scanner.totalSize, countStyle: .file))")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if scanner.isScanning {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.65)
                        Text(scanner.scanProgress).font(.caption).foregroundColor(.secondary).lineLimit(1)
                    }
                }
                Picker("", selection: $scanner.categoryFilter) {
                    Text(L("Tutte categorie", "All categories")).tag(Optional<FileItem.FileCategory>.none)
                    ForEach(FileItem.FileCategory.allCases, id: \.self) {
                        Text($0.displayName).tag(Optional($0))
                    }
                }.pickerStyle(.menu).frame(width: 140)
                Menu {
                    Button {
                        selection.removeAll()
                        scanner.filterMode = .all
                        scanner.sortMode = .riskScore
                        scanner.scan()
                    } label: { Label(L("Tutti", "All"), systemImage: "square.grid.2x2") }
                    Button {
                        selection.removeAll()
                        scanner.filterMode = .unused90
                        scanner.sortMode = .lastUsed
                        scanner.scan()
                    } label: { Label(L("Non usati 3+ mesi", "Unused 3+ months"), systemImage: "clock") }
                    Button {
                        selection.removeAll()
                        scanner.filterMode = .unused180
                        scanner.sortMode = .lastUsed
                        scanner.scan()
                    } label: { Label(L("Non usati 6+ mesi", "Unused 6+ months"), systemImage: "clock.badge.xmark") }
                    Button {
                        selection.removeAll()
                        scanner.filterMode = .all
                        scanner.sortMode = .size
                        scanner.scan()
                    } label: { Label(L("Per dimensione", "By size"), systemImage: "arrow.up.arrow.down") }
                } label: {
                    Label(L("Scansiona", "Scan"), systemImage: "arrow.clockwise")
                }
                .disabled(scanner.isScanning)
                .menuStyle(.borderlessButton)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .opacity(scanner.isScanning ? 0.5 : 1.0)
            }
            .padding(.horizontal, 20).padding(.vertical, 10)

            if !selection.isEmpty {
                SelectionBar(
                    count: selection.count,
                    size: selectedSize,
                    onClear: { selection.removeAll() },
                    onDelete: { showBulkConfirm = true }
                )
            }

            Divider()

            if scanner.files.isEmpty && !scanner.isScanning {
                EmptyState(icon: "doc.fill", text: L("Premi Scansiona per cercare file grandi o inutilizzati", "Press Scan to find large or unused files"))
            } else {
                HStack(spacing: 0) {
                    Toggle("", isOn: Binding(
                        get: { allChecked },
                        set: { v in
                            if v { scanner.filteredFiles.forEach { selection.insert($0.id) } }
                            else { selection.removeAll() }
                        }
                    ))
                    .toggleStyle(.checkbox).frame(width: 28)
                    .help(allChecked ? L("Deseleziona tutto", "Deselect all") : L("Seleziona tutto", "Select all"))

                    Text(L("File", "File")).frame(maxWidth: .infinity, alignment: .leading)
                    Text(L("Categoria", "Category")).frame(width: 100, alignment: .leading)
                    Text(L("Dimensione", "Size")).frame(width: 110, alignment: .trailing)
                    Text(L("Ultima modifica", "Last modified")).frame(width: 140, alignment: .trailing)
                    Text(L("Suggerimento", "Suggestion")).frame(width: 180, alignment: .center)
                    Text(L("Azioni", "Actions")).frame(width: 60, alignment: .center)
                }
                .font(.caption).foregroundColor(.secondary)
                .padding(.horizontal, 20).padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))

                Divider()
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(scanner.filteredFiles) { item in
                            FileRow(
                                item: item,
                                isChecked: selection.contains(item.id),
                                onToggle: {
                                    if selection.contains(item.id) { selection.remove(item.id) }
                                    else { selection.insert(item.id) }
                                },
                                onReveal: { scanner.revealInFinder(item) },
                                onDelete: { singleTarget = item; showSingleConfirm = true }
                            )
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }

            if !scanner.files.isEmpty {
                FooterBar {
                    let high = scanner.filteredFiles.filter { $0.riskScore >= 70 }
                    let sz   = high.reduce(Int64(0)) { $0 + $1.size }
                    Text(L(
                        "\(high.count) file consigliati · risparmio potenziale: \(ByteCountFormatter.string(fromByteCount: sz, countStyle: .file))",
                        "\(high.count) files suggested · potential saving: \(ByteCountFormatter.string(fromByteCount: sz, countStyle: .file))"
                    )).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            scanner.minSizeMB = settings.minFileSizeMB
            scanner.additionalBlocklist = Set(settings.excludedFolders)
            if settings.autoScanOnOpen && scanner.files.isEmpty { scanner.scan() }
        }
        .onChange(of: settings.minFileSizeMB) { _, mb in scanner.minSizeMB = mb }
        .onChange(of: settings.excludedFolders) { _, folders in
            scanner.additionalBlocklist = Set(folders)
        }
        .onChange(of: scanner.isScanning) { _, scanning in
            guard !scanning && !scanner.files.isEmpty && settings.weeklyNotification else { return }
            let t = settings.suggestionThresholdMonths * 30
            let bytes = scanner.files
                .filter { $0.unusedDays > t }
                .reduce(Int64(0)) { $0 + $1.size }
            if bytes > 0 { settings.scheduleWeeklyWithData(unusedBytes: bytes) }
        }
        .alert(L("Eliminare \(selection.count) elementi?", "Delete \(selection.count) items?"), isPresented: $showBulkConfirm) {
            Button(L("Sposta nel Cestino", "Move to Trash"), role: .destructive) {
                let toDelete = selectedItems
                selection.removeAll()
                toDelete.forEach { scanner.moveToTrash($0) }
            }
            Button(L("Annulla", "Cancel"), role: .cancel) {}
        } message: {
            Text(L(
                "Verranno spostati nel Cestino \(selection.count) elementi (\(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))).",
                "\(selection.count) items (\(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))) will be moved to Trash."
            ))
        }
        .alert(L("Eliminare \"\(singleTarget?.name ?? "")\"?", "Delete \"\(singleTarget?.name ?? "")\"?"), isPresented: $showSingleConfirm) {
            Button(L("Sposta nel Cestino", "Move to Trash"), role: .destructive) {
                if let i = singleTarget { selection.remove(i.id); scanner.moveToTrash(i) }
            }
            Button(L("Annulla", "Cancel"), role: .cancel) {}
        } message: {
            Text(L("Il file verrà spostato nel Cestino. Potrai recuperarlo prima di svuotarlo.",
                   "The file will be moved to Trash. You can recover it before emptying it."))
        }
    }
}

// MARK: - Selection bar

struct SelectionBar: View {
    let count: Int
    let size: Int64
    let onClear: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
            Text(L("\(count) selezionat\(count == 1 ? "o" : "i") · \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))",
                   "\(count) selected · \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))"))
                .font(.callout).bold()
            Spacer()
            Button(L("Deseleziona tutto", "Deselect all"), action: onClear)
                .buttonStyle(.plain).foregroundColor(.secondary).font(.callout)
            Button(action: onDelete) {
                Label(L("Sposta nel Cestino", "Move to Trash"), systemImage: "trash")
                    .font(.callout)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(.horizontal, 20).padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.07))
    }
}

// MARK: - Rows

struct AppRow: View {
    let app: AppInfo
    let isChecked: Bool
    let onToggle: () -> Void
    let onReveal: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Toggle("", isOn: Binding(get: { isChecked }, set: { _ in onToggle() }))
                .toggleStyle(.checkbox).frame(width: 28)

            HStack(spacing: 10) {
                if let icon = app.icon {
                    Image(nsImage: icon).resizable().frame(width: 26, height: 26)
                }
                Text(app.name).font(.body).lineLimit(1)
            }.frame(maxWidth: .infinity, alignment: .leading)

            SizeCell(size: app.size, threshold500: true)
            DateCell(text: app.lastUsedFormatted, days: app.unusedDays)
            SuggestionBadge(label: app.suggestion, colorName: app.suggestionColor)
            ActionButtons(onReveal: onReveal, onDelete: onDelete)
        }
        .rowStyle(isChecked: isChecked, isHovered: isHovered, onTap: onToggle, onHover: { isHovered = $0 })
    }
}

struct FileRow: View {
    let item: FileItem
    let isChecked: Bool
    let onToggle: () -> Void
    let onReveal: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Toggle("", isOn: Binding(get: { isChecked }, set: { _ in onToggle() }))
                .toggleStyle(.checkbox).frame(width: 28)

            HStack(spacing: 8) {
                Button(action: item.isDirectory ? onReveal : {}) {
                    Image(systemName: item.isDirectory ? "folder.fill" : item.category.icon)
                        .foregroundColor(item.isDirectory ? .orange : .accentColor)
                        .font(.system(size: 16))
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!item.isDirectory)
                .help(item.isDirectory ? L("Apri in Finder", "Open in Finder") : "")

                Text(item.name).font(.body).lineLimit(1)
                if item.isDirectory {
                    Text(L("cartella", "folder")).font(.caption2).foregroundColor(.secondary)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }.frame(maxWidth: .infinity, alignment: .leading)

            Text(item.category.displayName)
                .font(.caption).foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            SizeCell(size: item.size, threshold500: false)
            DateCell(text: item.lastUsedFormatted, days: item.unusedDays)
            SuggestionBadge(label: item.suggestion, colorName: item.suggestionColor)
            ActionButtons(onReveal: onReveal, onDelete: onDelete)
        }
        .rowStyle(isChecked: isChecked, isHovered: isHovered, onTap: onToggle, onHover: { isHovered = $0 })
    }
}

// MARK: - Shared sub-views

struct SizeCell: View {
    let size: Int64; let threshold500: Bool
    var body: some View {
        Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
            .font(.body.monospacedDigit()).frame(width: 110, alignment: .trailing)
            .foregroundColor(size > 1_000_000_000 ? .red : (threshold500 && size > 500_000_000) ? .orange : .primary)
    }
}

struct DateCell: View {
    let text: String; let days: Int
    var body: some View {
        Text(text).font(.body).frame(width: 140, alignment: .trailing)
            .foregroundColor(days > 180 ? .red : days > 90 ? .orange : .primary)
    }
}

struct SuggestionBadge: View {
    let label: String; let colorName: String
    var color: Color {
        switch colorName {
        case "red":    return .red
        case "orange": return .orange
        case "yellow": return Color(red: 0.8, green: 0.7, blue: 0)
        default:       return .green
        }
    }
    var body: some View {
        Text(label).font(.caption).bold()
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15)).foregroundColor(color)
            .clipShape(Capsule()).frame(width: 180)
    }
}

struct ActionButtons: View {
    let onReveal: () -> Void; let onDelete: () -> Void
    var body: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.system(size: 14))
                .foregroundColor(.red)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(L("Sposta nel Cestino", "Move to Trash"))
        .frame(width: 80)
    }
}

struct EmptyState: View {
    let icon: String; let text: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 52)).foregroundColor(.secondary)
            Text(text).font(.title3).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FooterBar<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        Divider()
        HStack {
            Image(systemName: "info.circle").foregroundColor(.secondary)
            content
            Spacer()
        }
        .padding(.horizontal, 20).padding(.vertical, 7)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

private func uninstall() {
    let plist = NSHomeDirectory() + "/Library/LaunchAgents/com.timecleaner.app.plist"
    let unload = Process()
    unload.launchPath = "/bin/launchctl"
    unload.arguments = ["unload", plist]
    try? unload.run(); unload.waitUntilExit()
    try? FileManager.default.removeItem(atPath: plist)
    NSWorkspace.shared.recycle([URL(fileURLWithPath: "/Applications/TimeCleaner.app")]) { _, _ in }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { NSApp.terminate(nil) }
}

extension View {
    func rowStyle(isChecked: Bool, isHovered: Bool, onTap: @escaping () -> Void, onHover: @escaping (Bool) -> Void) -> some View {
        self
            .padding(.horizontal, 20).padding(.vertical, 7)
            .background(isChecked ? Color.accentColor.opacity(0.08) : isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear)
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { onTap() })
            .onHover(perform: onHover)
    }
}

