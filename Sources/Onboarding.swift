import SwiftUI
import AppKit

struct OnboardingView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Icon area
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "trash")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.accentColor)
            }
            .padding(.top, 36)

            Text("TimeCleaner è nella menu bar")
                .font(.title2).bold()
                .multilineTextAlignment(.center)
                .padding(.top, 18)
                .padding(.horizontal, 24)

            Text("Clicca sull'icona del bidone 🗑 in alto a destra per aprire l'app in qualsiasi momento.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 12)
                .padding(.horizontal, 32)

            // Arrow hint
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(width: 180, height: 32)
                    .overlay(
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                            Text("TimeCleaner")
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                    )
                Image(systemName: "wifi")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Image(systemName: "battery.100")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            Button(action: onDismiss) {
                Text("Ho capito")
                    .font(.body).bold()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.top, 28)
            .padding(.bottom, 32)
        }
        .frame(width: 360)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
