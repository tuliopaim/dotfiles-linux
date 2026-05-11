#!/usr/bin/env swift
import AppKit
import Foundation

let args = CommandLine.arguments
let stateFile = args.count > 1 ? args[1] : ""
let lockDir = args.count > 2 ? args[2] : ""
let idleGraceSeconds = TimeInterval(ProcessInfo.processInfo.environment["MACOS_STT_STATUS_IDLE_GRACE_SECONDS"] ?? "1.5") ?? 1.5

final class StatusController: NSObject {
  private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private var idleSince: Date?

  override init() {
    super.init()
    NSApp.setActivationPolicy(.accessory)
    if let button = item.button {
      button.font = NSFont.monospacedSystemFont(ofSize: 16, weight: .semibold)
      button.toolTip = "macOS STT"
    }
    Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
      self?.refresh()
    }
    refresh()
  }

  private func exists(_ path: String) -> Bool {
    !path.isEmpty && FileManager.default.fileExists(atPath: path)
  }

  private func refresh() {
    let processing = exists(lockDir)
    let recording = exists(stateFile)

    if processing {
      set(title: "⏳", tooltip: "macOS STT: transcribing")
      idleSince = nil
      return
    }

    if recording {
      set(title: "●", tooltip: "macOS STT: recording", color: .systemRed)
      idleSince = nil
      return
    }

    if idleSince == nil {
      idleSince = Date()
      set(title: "✓", tooltip: "macOS STT: done", color: .systemGreen)
      return
    }

    if let idleSince, Date().timeIntervalSince(idleSince) >= idleGraceSeconds {
      NSStatusBar.system.removeStatusItem(item)
      NSApp.terminate(nil)
    }
  }

  private func set(title: String, tooltip: String, color: NSColor? = nil) {
    guard let button = item.button else { return }
    button.toolTip = tooltip
    if let color {
      button.attributedTitle = NSAttributedString(
        string: title,
        attributes: [
          .foregroundColor: color,
          .font: NSFont.monospacedSystemFont(ofSize: 16, weight: .bold),
        ]
      )
    } else {
      button.attributedTitle = NSAttributedString(
        string: title,
        attributes: [.font: NSFont.monospacedSystemFont(ofSize: 16, weight: .semibold)]
      )
    }
  }
}

let app = NSApplication.shared
let controller = StatusController()
withExtendedLifetime(controller) {
  app.run()
}
