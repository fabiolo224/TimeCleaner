import Foundation
import AppKit

class UpdateChecker: ObservableObject {
    @Published var updateAvailable = false
    @Published var latestVersion = ""
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0

    private let versionURL = "https://raw.githubusercontent.com/fabiolo224/TimeCleaner/main/version.json"
    private let currentVersion = "1.0"
    private var downloadURL = ""

    func checkForUpdates() {
        guard let url = URL(string: versionURL) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                  let remote = json["version"],
                  let dlURL = json["url"] else { return }
            DispatchQueue.main.async {
                if remote.compare(self.currentVersion, options: .numeric) == .orderedDescending {
                    self.latestVersion = remote
                    self.downloadURL = dlURL
                    self.updateAvailable = true
                }
            }
        }.resume()
    }

    func downloadAndInstall() {
        guard let url = URL(string: downloadURL) else { return }
        isDownloading = true
        downloadProgress = 0

        let task = URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL, error == nil else {
                DispatchQueue.main.async { self.isDownloading = false }
                return
            }
            let zipPath = FileManager.default.temporaryDirectory
                .appendingPathComponent("TimeCleaner_update.zip")
            try? FileManager.default.moveItem(at: tempURL, to: zipPath)
            self.applyUpdate(zipPath: zipPath)
        }

        // Osservazione progresso
        let obs = task.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async { self.downloadProgress = progress.fractionCompleted }
        }
        _ = obs
        task.resume()
    }

    private func applyUpdate(zipPath: URL) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TimeCleaner_update_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Estrai zip
        let unzip = Process()
        unzip.launchPath = "/usr/bin/unzip"
        unzip.arguments = ["-o", zipPath.path, "-d", tempDir.path]
        try? unzip.run()
        unzip.waitUntilExit()

        let newApp = tempDir.appendingPathComponent("TimeCleaner.app").path
        let installPath = "/Applications/TimeCleaner.app"

        // Script che aspetta la chiusura, sostituisce e riapre
        let script = """
        #!/bin/bash
        sleep 1.5
        rm -rf "\(installPath)"
        cp -R "\(newApp)" "\(installPath)"
        xattr -cr "\(installPath)"
        open "\(installPath)"
        """
        let scriptPath = "/tmp/timecleaner_update.sh"
        try? script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)

        let launcher = Process()
        launcher.launchPath = "/bin/bash"
        launcher.arguments = [scriptPath]
        try? launcher.run()

        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }
}
