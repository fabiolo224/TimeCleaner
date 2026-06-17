import SwiftUI
import AppKit

// MARK: - Root

struct ContentView: View {
    @State private var tab: Tab = .apps
    enum Tab { case apps, files }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TabButton(title: "Applicazioni", icon: "app.badge", selected: tab == .apps)  { tab = .apps }
                TabButton(title: "File",          icon: "doc.fill",  selected: tab == .files) { tab = .files }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            if tab == .apps { AppsView() } else { FilesView() }
        }
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
            // Toolbar
            HStack(spacing: 10) {
                if scanner.apps.isEmpty {
                    Text("Scansiona le applicazioni installate")
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
                Picker("", selection: $scanner.filterMode) {
                    ForEach(AppScanner.FilterMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.menu).frame(width: 160)
                Picker("", selection: $scanner.sortMode) {
                    ForEach(AppScanner.SortMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.menu).frame(width: 130)
                Button(action: { selection.removeAll(); scanner.scan() }) {
                    Label("Scansiona", systemImage: "arrow.clockwise")
                }.disabled(scanner.isScanning).buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20).padding(.vertical, 10)

            // Selection action bar
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
                EmptyState(icon: "app.badge", text: "Premi Scansiona per analizzare le app")
            } else {
                // Column header with select-all checkbox
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
                    .help(allChecked ? "Deseleziona tutto" : "Seleziona tutto")

                    Text("Applicazione").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Dimensione").frame(width: 110, alignment: .trailing)
                    Text("Ultimo utilizzo").frame(width: 140, alignment: .trailing)
                    Text("Suggerimento").frame(width: 180, alignment: .center)
                    Text("Azioni").frame(width: 60, alignment: .center)
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
                    Text("\(high.count) app consigliate · risparmio potenziale: \(ByteCountFormatter.string(fromByteCount: sz, countStyle: .file))")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
        // Bulk delete
        .alert("Eliminare \(selection.count) app?", isPresented: $showBulkConfirm) {
            Button("Sposta nel Cestino", role: .destructive) {
                let toDelete = selectedApps
                selection.removeAll()
                toDelete.forEach { scanner.moveToTrash($0) }
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("Verranno spostate nel Cestino \(selection.count) app (\(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))). Potrai recuperarle prima di svuotarlo.")
        }
        // Single delete
        .alert("Eliminare \"\(singleTarget?.name ?? "")\"?", isPresented: $showSingleConfirm) {
            Button("Sposta nel Cestino", role: .destructive) {
                if let a = singleTarget { selection.remove(a.id); scanner.moveToTrash(a) }
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("L'app verrà spostata nel Cestino. Potrai recuperarla prima di svuotarlo.")
        }
    }
}

// MARK: - Files tab

struct FilesView: View {
    @StateObject private var scanner = FileScanner()
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
                    Text("Scansiona Download, Documenti, Cache e altro")
                        .font(.caption).foregroundColor(.secondary)
                } else {
                    Text("\(scanner.files.count) file · \(ByteCountFormatter.string(fromByteCount: scanner.totalSize, countStyle: .file))")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if scanner.isScanning {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.65)
                        Text(scanner.scanProgress).font(.caption).foregroundColor(.secondary).lineLimit(1)
                    }
                }
                HStack(spacing: 4) {
                    Text("Min:").font(.caption).foregroundColor(.secondary)
                    Picker("", selection: $scanner.minSizeMB) {
                        Text("1 MB").tag(1.0); Text("10 MB").tag(10.0)
                        Text("50 MB").tag(50.0); Text("100 MB").tag(100.0); Text("500 MB").tag(500.0)
                    }.pickerStyle(.menu).frame(width: 80)
                }
                Picker("", selection: $scanner.categoryFilter) {
                    Text("Tutte categorie").tag(Optional<FileItem.FileCategory>.none)
                    ForEach(FileItem.FileCategory.allCases, id: \.self) {
                        Text($0.rawValue).tag(Optional($0))
                    }
                }.pickerStyle(.menu).frame(width: 140)
                Picker("", selection: $scanner.filterMode) {
                    ForEach(FileScanner.FilterMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.menu).frame(width: 155)
                Picker("", selection: $scanner.sortMode) {
                    ForEach(FileScanner.SortMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.menu).frame(width: 130)
                Button(action: { selection.removeAll(); scanner.scan() }) {
                    Label("Scansiona", systemImage: "arrow.clockwise")
                }.disabled(scanner.isScanning).buttonStyle(.borderedProminent)
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
                EmptyState(icon: "doc.fill", text: "Premi Scansiona per cercare file grandi o inutilizzati")
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
                    .help(allChecked ? "Deseleziona tutto" : "Seleziona tutto")

                    Text("File").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Categoria").frame(width: 100, alignment: .leading)
                    Text("Dimensione").frame(width: 110, alignment: .trailing)
                    Text("Ultima modifica").frame(width: 140, alignment: .trailing)
                    Text("Suggerimento").frame(width: 180, alignment: .center)
                    Text("Azioni").frame(width: 60, alignment: .center)
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
                    Text("\(high.count) file consigliati · risparmio potenziale: \(ByteCountFormatter.string(fromByteCount: sz, countStyle: .file))")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .alert("Eliminare \(selection.count) elementi?", isPresented: $showBulkConfirm) {
            Button("Sposta nel Cestino", role: .destructive) {
                let toDelete = selectedItems
                selection.removeAll()
                toDelete.forEach { scanner.moveToTrash($0) }
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("Verranno spostati nel Cestino \(selection.count) elementi (\(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))).")
        }
        .alert("Eliminare \"\(singleTarget?.name ?? "")\"?", isPresented: $showSingleConfirm) {
            Button("Sposta nel Cestino", role: .destructive) {
                if let i = singleTarget { selection.remove(i.id); scanner.moveToTrash(i) }
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("Il file verrà spostato nel Cestino. Potrai recuperarlo prima di svuotarlo.")
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
            Text("\(count) selezionat\(count == 1 ? "o" : "i") · \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
                .font(.callout).bold()
            Spacer()
            Button("Deseleziona tutto", action: onClear)
                .buttonStyle(.plain).foregroundColor(.secondary).font(.callout)
            Button(action: onDelete) {
                Label("Sposta nel Cestino", systemImage: "trash")
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
                .help(item.isDirectory ? "Apri in Finder" : "")

                Text(item.name).font(.body).lineLimit(1)
                if item.isDirectory {
                    Text("cartella").font(.caption2).foregroundColor(.secondary)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }.frame(maxWidth: .infinity, alignment: .leading)

            Text(item.category.rawValue)
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
        .help("Sposta nel Cestino")
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

extension FileItem.FileCategory: CaseIterable {
    static var allCases: [FileItem.FileCategory] = [.download, .document, .video, .archive, .image, .cache, .other]
}
