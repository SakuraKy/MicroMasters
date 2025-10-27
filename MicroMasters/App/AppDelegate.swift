//
//  AppDelegate.swift
//  MicroMasters
//
//  Created by Codex CLI.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var statusItem: NSStatusItem = {
        NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }()
    private var studyManager: StudyManager!
    private var notificationManager: NotificationManager!
    private var statusBarController: StatusBarController!

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("MicroMasters: applicationDidFinishLaunching")
        studyManager = StudyManager()
        notificationManager = NotificationManager(studyManager: studyManager)
        statusBarController = StatusBarController(statusItem: statusItem,
                                                  studyManager: studyManager,
                                                  notificationManager: notificationManager)
        notificationManager.requestAuthorizationIfNeeded()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 菜单栏应用不应该因为关闭窗口而退出
        false
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}
