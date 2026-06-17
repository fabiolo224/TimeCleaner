import Foundation
import AppKit

// MARK: - Shared helpers

func openInFinder(_ path: String) {
    NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
}

func daysSince(_ date: Date?) -> Int {
    guard let date else { return Int.max }
    return Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
}

func formatLastUsed(_ date: Date?) -> String {
    guard let date else { return L("Mai usato", "Never used") }
    let days = daysSince(date)
    if days == 0 { return L("Oggi", "Today") }
    if days == 1 { return L("Ieri", "Yesterday") }
    if days < 30 { return L("\(days) giorni fa", "\(days) days ago") }
    if days < 365 { return L("\(days / 30) mesi fa", "\(days / 30) months ago") }
    return L("\(days / 365) anni fa", "\(days / 365) years ago")
}

func calcRiskScore(size: Int64, unusedDays: Int) -> Int {
    let sizeScore = min(Int(size / (1024 * 1024 * 100)), 50)
    let timeScore: Int
    if unusedDays == Int.max   { timeScore = 50 }
    else if unusedDays > 365  { timeScore = 50 }
    else if unusedDays > 180  { timeScore = 35 }
    else if unusedDays > 90   { timeScore = 20 }
    else if unusedDays > 30   { timeScore = 10 }
    else                       { timeScore = 0  }
    return sizeScore + timeScore
}

func suggestionLabel(_ score: Int) -> String {
    if score >= 70 { return L("Fortemente consigliato", "Strongly suggested") }
    if score >= 40 { return L("Consigliato", "Suggested") }
    if score >= 20 { return L("Considerare", "Consider") }
    return L("Tenere", "Keep")
}

func suggestionColorName(_ score: Int) -> String {
    if score >= 70 { return "red" }
    if score >= 40 { return "orange" }
    if score >= 20 { return "yellow" }
    return "green"
}

// MARK: - App

struct AppInfo: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let size: Int64
    let lastUsed: Date?
    let icon: NSImage?

    var sizeFormatted: String { ByteCountFormatter.string(fromByteCount: size, countStyle: .file) }
    var lastUsedFormatted: String { formatLastUsed(lastUsed) }
    var unusedDays: Int { daysSince(lastUsed) }
    var riskScore: Int { calcRiskScore(size: size, unusedDays: unusedDays) }
    var suggestion: String { suggestionLabel(riskScore) }
    var suggestionColor: String { suggestionColorName(riskScore) }
}

// MARK: - File

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let size: Int64
    let lastModified: Date?
    let isDirectory: Bool
    let category: FileCategory

    var sizeFormatted: String { ByteCountFormatter.string(fromByteCount: size, countStyle: .file) }
    var lastUsedFormatted: String { formatLastUsed(lastModified) }
    var unusedDays: Int { daysSince(lastModified) }
    var riskScore: Int { calcRiskScore(size: size, unusedDays: unusedDays) }
    var suggestion: String { suggestionLabel(riskScore) }
    var suggestionColor: String { suggestionColorName(riskScore) }

    enum FileCategory: String, Hashable, CaseIterable {
        case download = "download"
        case document = "document"
        case video    = "video"
        case archive  = "archive"
        case image    = "image"
        case cache    = "cache"
        case other    = "other"

        static var allCases: [FileCategory] = [.download, .document, .video, .archive, .image, .cache, .other]

        var displayName: String {
            switch self {
            case .download: return L("Download", "Downloads")
            case .document: return L("Documenti", "Documents")
            case .video:    return L("Video", "Videos")
            case .archive:  return L("Archivi", "Archives")
            case .image:    return L("Immagini", "Images")
            case .cache:    return L("Cache", "Cache")
            case .other:    return L("Altro", "Other")
            }
        }

        var icon: String {
            switch self {
            case .download: return "arrow.down.circle"
            case .document: return "doc"
            case .video:    return "film"
            case .archive:  return "archivebox"
            case .image:    return "photo"
            case .cache:    return "internaldrive"
            case .other:    return "doc.fill"
            }
        }
    }
}

func fileCategory(for url: URL) -> FileItem.FileCategory {
    let ext = url.pathExtension.lowercased()
    switch ext {
    case "mp4","mov","avi","mkv","m4v","wmv","flv","webm": return .video
    case "zip","tar","gz","bz2","rar","7z","dmg","pkg","xip": return .archive
    case "jpg","jpeg","png","gif","bmp","tiff","heic","webp","svg": return .image
    case "pdf","doc","docx","xls","xlsx","ppt","pptx","pages","numbers","key","txt","rtf","csv": return .document
    default: return .other
    }
}

// MARK: - App Scanner

class AppScanner: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var isScanning = false
    @Published var scanProgress = ""
    @Published var sortMode: SortMode = .riskScore
    @Published var filterMode: FilterMode = .all

    enum SortMode: String, CaseIterable, Hashable {
        case riskScore = "riskScore"
        case size      = "size"
        case lastUsed  = "lastUsed"
        case name      = "name"

        var displayName: String {
            switch self {
            case .riskScore: return L("Suggeriti", "Suggested")
            case .size:      return L("Dimensione", "Size")
            case .lastUsed:  return L("Ultimo utilizzo", "Last used")
            case .name:      return L("Nome", "Name")
            }
        }
    }

    enum FilterMode: String, CaseIterable, Hashable {
        case all       = "all"
        case unused90  = "unused90"
        case unused180 = "unused180"
        case large     = "large"

        var displayName: String {
            switch self {
            case .all:       return L("Tutti", "All")
            case .unused90:  return L("Non usati 3+ mesi", "Unused 3+ months")
            case .unused180: return L("Non usati 6+ mesi", "Unused 6+ months")
            case .large:     return L("Grandi (>500MB)", "Large (>500MB)")
            }
        }
    }

    var filteredApps: [AppInfo] {
        var result = apps
        switch filterMode {
        case .all: break
        case .unused90:  result = result.filter { $0.unusedDays > 90 }
        case .unused180: result = result.filter { $0.unusedDays > 180 }
        case .large:     result = result.filter { $0.size > 500 * 1024 * 1024 }
        }
        switch sortMode {
        case .riskScore: result.sort { $0.riskScore > $1.riskScore }
        case .size:      result.sort { $0.size > $1.size }
        case .lastUsed:  result.sort { ($0.lastUsed ?? .distantPast) < ($1.lastUsed ?? .distantPast) }
        case .name:      result.sort { $0.name < $1.name }
        }
        return result
    }

    var totalSize: Int64 { apps.reduce(0) { $0 + $1.size } }

    private let systemBundlePrefixes = ["com.apple.", "com.apple.dt.", "com.apple.iWork."]

    private func isSystemApp(_ appURL: URL) -> Bool {
        if appURL.path.hasPrefix("/System/") { return true }
        let plist = appURL.appendingPathComponent("Contents/Info.plist")
        if let dict = NSDictionary(contentsOf: plist),
           let bundleID = dict["CFBundleIdentifier"] as? String {
            return systemBundlePrefixes.contains(where: { bundleID.hasPrefix($0) })
        }
        return false
    }

    func scan() {
        isScanning = true
        apps = []
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let dirs = ["/Applications", "\(NSHomeDirectory())/Applications"]
            var found: [AppInfo] = []
            for dir in dirs {
                let url = URL(fileURLWithPath: dir)
                guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else { continue }
                for appURL in contents.filter({ $0.pathExtension == "app" }) {
                    if self.isSystemApp(appURL) { continue }
                    DispatchQueue.main.async { self.scanProgress = appURL.deletingPathExtension().lastPathComponent }
                    let size = self.folderSize(at: appURL)
                    let lastUsed = self.mdlsDate(for: appURL)
                    let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                    icon.size = NSSize(width: 32, height: 32)
                    found.append(AppInfo(name: appURL.deletingPathExtension().lastPathComponent,
                        path: appURL, size: size, lastUsed: lastUsed, icon: icon))
                }
            }
            DispatchQueue.main.async { self.apps = found; self.isScanning = false; self.scanProgress = "" }
        }
    }

    func folderSize(at url: URL) -> Int64 {
        var size: Int64 = 0
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else { return 0 }
        for case let fileURL as URL in enumerator {
            size += (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { Int64($0) } ?? 0
        }
        return size
    }

    func mdlsDate(for url: URL) -> Date? {
        let task = Process()
        task.launchPath = "/usr/bin/mdls"
        task.arguments = ["-name", "kMDItemLastUsedDate", "-raw", url.path]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        try? task.run()
        task.waitUntilExit()
        let raw = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if raw == "(null)" || raw.isEmpty { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter.date(from: raw)
    }

    func moveToTrash(_ app: AppInfo) {
        NSWorkspace.shared.recycle([app.path]) { _, _ in
            DispatchQueue.main.async { self.apps.removeAll { $0.id == app.id } }
        }
    }

    func revealInFinder(_ app: AppInfo) {
        openInFinder(app.path.deletingLastPathComponent().path)
    }
}

// MARK: - File Scanner

class FileScanner: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var isScanning = false
    @Published var scanProgress = ""
    @Published var sortMode: SortMode = .riskScore
    @Published var filterMode: FilterMode = .all
    @Published var categoryFilter: FileItem.FileCategory? = nil
    @Published var minSizeMB: Double = 10

    enum SortMode: String, CaseIterable, Hashable {
        case riskScore = "riskScore"
        case size      = "size"
        case lastUsed  = "lastUsed"
        case name      = "name"

        var displayName: String {
            switch self {
            case .riskScore: return L("Suggeriti", "Suggested")
            case .size:      return L("Dimensione", "Size")
            case .lastUsed:  return L("Ultima modifica", "Last modified")
            case .name:      return L("Nome", "Name")
            }
        }
    }

    enum FilterMode: String, CaseIterable, Hashable {
        case all       = "all"
        case unused90  = "unused90"
        case unused180 = "unused180"
        case large     = "large"

        var displayName: String {
            switch self {
            case .all:       return L("Tutti", "All")
            case .unused90:  return L("Non usati 3+ mesi", "Unused 3+ months")
            case .unused180: return L("Non usati 6+ mesi", "Unused 6+ months")
            case .large:     return L("Grandi (>1GB)", "Large (>1GB)")
            }
        }
    }

    private let scanRoots: [String] = [
        "~/Downloads", "~/Documents", "~/Desktop", "~/Movies",
        "~/Music/iTunes/iTunes Media/Downloads",
        "~/Library/Caches", "~/Library/Logs",
        "~/Library/Application Support/MobileSync/Backup",
        "~/Library/Developer/Xcode/DerivedData",
        "~/Library/Developer/CoreSimulator/Devices",
        "~/Public", "~/Shared"
    ].map { NSString(string: $0).expandingTildeInPath }

    private let blocklist: Set<String> = [
        "/System", "/usr", "/bin", "/sbin", "/etc", "/var",
        "/private/var", "/private/etc", "/Library/Apple",
        "/Library/CoreMediaIO", "/Library/Extensions",
        NSHomeDirectory() + "/Library/Preferences",
        NSHomeDirectory() + "/Library/Keychains",
        NSHomeDirectory() + "/Library/Application Support/com.apple",
        NSHomeDirectory() + "/Library/Safari",
        NSHomeDirectory() + "/Library/Mail",
        NSHomeDirectory() + "/Library/Messages"
    ]

    var filteredFiles: [FileItem] {
        var result = files
        if let cat = categoryFilter { result = result.filter { $0.category == cat } }
        switch filterMode {
        case .all: break
        case .unused90:  result = result.filter { $0.unusedDays > 90 }
        case .unused180: result = result.filter { $0.unusedDays > 180 }
        case .large:     result = result.filter { $0.size > 1_000_000_000 }
        }
        switch sortMode {
        case .riskScore: result.sort { $0.riskScore > $1.riskScore }
        case .size:      result.sort { $0.size > $1.size }
        case .lastUsed:  result.sort { ($0.lastModified ?? .distantPast) < ($1.lastModified ?? .distantPast) }
        case .name:      result.sort { $0.name < $1.name }
        }
        return result
    }

    var totalSize: Int64 { files.reduce(0) { $0 + $1.size } }

    func scan() {
        isScanning = true
        files = []
        let minBytes = Int64(minSizeMB * 1024 * 1024)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var found: [FileItem] = []
            let fm = FileManager.default
            for root in self.scanRoots {
                let rootURL = URL(fileURLWithPath: root)
                guard fm.fileExists(atPath: root) else { continue }
                DispatchQueue.main.async { self.scanProgress = rootURL.lastPathComponent }
                let isCacheOrLog = root.contains("/Caches") || root.contains("/Logs")
                    || root.contains("DerivedData") || root.contains("CoreSimulator")
                    || root.contains("MobileSync")
                if isCacheOrLog {
                    guard let subs = try? fm.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil) else { continue }
                    for sub in subs {
                        if self.isBlocked(sub) { continue }
                        let size = self.sizeOf(sub)
                        if size < minBytes { continue }
                        var isDir: ObjCBool = false
                        fm.fileExists(atPath: sub.path, isDirectory: &isDir)
                        found.append(FileItem(name: sub.lastPathComponent, path: sub, size: size,
                            lastModified: self.modDate(of: sub), isDirectory: isDir.boolValue, category: .cache))
                    }
                    continue
                }
                guard let enumerator = fm.enumerator(at: rootURL,
                    includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
                for case let url as URL in enumerator {
                    if self.isBlocked(url) { enumerator.skipDescendants(); continue }
                    guard let res = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey]) else { continue }
                    if res.isDirectory == true { continue }
                    let fileSize = Int64(res.fileSize ?? 0)
                    if fileSize < minBytes { continue }
                    found.append(FileItem(name: url.lastPathComponent, path: url, size: fileSize,
                        lastModified: res.contentModificationDate, isDirectory: false, category: fileCategory(for: url)))
                }
            }
            DispatchQueue.main.async { self.files = found; self.isScanning = false; self.scanProgress = "" }
        }
    }

    private func isBlocked(_ url: URL) -> Bool {
        let p = url.path
        return blocklist.contains(where: { p.hasPrefix($0) })
    }

    private func sizeOf(_ url: URL) -> Int64 {
        var size: Int64 = 0
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { Int64($0) } ?? 0
        }
        for case let f as URL in enumerator {
            size += (try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { Int64($0) } ?? 0
        }
        return size
    }

    private func modDate(of url: URL) -> Date? {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }

    func moveToTrash(_ item: FileItem) {
        NSWorkspace.shared.recycle([item.path]) { _, _ in
            DispatchQueue.main.async { self.files.removeAll { $0.id == item.id } }
        }
    }

    func revealInFinder(_ item: FileItem) {
        openInFinder(item.path.path)
    }
}
