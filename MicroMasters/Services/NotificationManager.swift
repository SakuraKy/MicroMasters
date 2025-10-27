//
//  NotificationManager.swift
//  MicroMasters
//
//  Created by Codex CLI.
//

import AppKit
import Foundation
import UserNotifications

final class NotificationManager: NSObject {
    enum CategoryID {
        static let study = "MicroMastersStudyCategory"
        static let quiz = "MicroMastersQuizCategory"
        static let feedback = "MicroMastersFeedbackCategory"
    }

    enum ActionID {
        static let remember = "MicroMastersRememberAction"
        static let skip = "MicroMastersSkipAction"
        static let speak = "MicroMastersSpeakAction"
        static let quizPrefix = "MicroMastersQuizOption_"
    }

    enum RequestID {
        static let study = "MicroMastersStudyRequest"
        static let quiz = "MicroMastersQuizRequest"
        static let feedback = "MicroMastersFeedbackRequest"
        static let info = "MicroMastersInfoRequest"
    }

    private struct StudySession {
        var words: [Word]
        var index: Int = 0

        var currentWord: Word? {
            guard index >= 0 && index < words.count else { return nil }
            return words[index]
        }

        mutating func advance() {
            index += 1
        }

        var isCompleted: Bool {
            index >= words.count
        }
    }

    private struct QuizState {
        let prompt: Word
        let options: [Word]
    }
    
    /// 测试会话 - 保存多个测试题
    private struct QuizSession {
        var quizzes: [(Word, [Word])]  // (正确答案, 选项列表)
        var index: Int = 0
        
        var currentQuiz: (Word, [Word])? {
            guard index >= 0 && index < quizzes.count else { return nil }
            return quizzes[index]
        }
        
        mutating func advance() {
            index += 1
        }
        
        var isCompleted: Bool {
            index >= quizzes.count
        }
        
        var progress: String {
            return "\(index + 1)/\(quizzes.count)"
        }
    }

    private let center = UNUserNotificationCenter.current()
    private let speechSynthesizer = NSSpeechSynthesizer()
    private let studyManager: StudyManager
    private var studySession: StudySession?
    private var quizState: QuizState?
    private var quizSession: QuizSession?  // 新增：测试会话
    private var staticCategories: Set<UNNotificationCategory> = []

    init(studyManager: StudyManager) {
        self.studyManager = studyManager
        super.init()
        // 设置 speechSynthesizer 的 delegate 为 nil 以避免回调问题
        speechSynthesizer.delegate = nil
        registerStaticCategories()
        center.delegate = self
    }

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                break
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error {
                        NSLog("通知授权失败: \(error)")
                    } else if !granted {
                        NSLog("用户拒绝通知授权")
                    }
                }
            case .denied:
                NSLog("通知被拒绝，请提示用户前往设置开启")
            @unknown default:
                break
            }
        }
    }

    func startStudySession(with words: [Word]) {
        guard !words.isEmpty else {
            postInfoNotification(message: "词库为空，无法开始学习，请先导入词库。")
            return
        }
        NSLog("📖 NotificationManager 收到 \(words.count) 个单词")
        studySession = StudySession(words: words, index: 0)
        quizState = nil
        scheduleNextStudyNotification()
    }

    func startStandaloneQuiz() {
        guard let quiz = studyManager.randomQuizQuestion() else {
            postInfoNotification(message: "词库不足，无法生成测验。")
            return
        }
        quizState = QuizState(prompt: quiz.prompt, options: quiz.options)
        studySession = nil
        scheduleQuizNotification()
    }
    
    /// 开始指定单词的测试（随机测试功能）
    func startQuizSession(with words: [Word]) {
        guard !words.isEmpty else {
            postInfoNotification(message: "没有可测试的单词。")
            return
        }
        
        NSLog("📖 开始随机测试 - 共 \(words.count) 个单词")
        
        // 为每个单词生成测验题
        var quizzes: [(Word, [Word])] = []
        for word in words {
            // 从所有单词中随机选择干扰项
            let allWords = studyManager.allWords()
            let distractors = allWords.filter { $0.term != word.term }.shuffled().prefix(2)
            let options = ([word] + distractors).shuffled()
            quizzes.append((word, Array(options)))
        }
        
        NSLog("📖 生成了 \(quizzes.count) 道测试题")
        
        // 创建测试会话
        quizSession = QuizSession(quizzes: quizzes, index: 0)
        studySession = nil
        
        // 开始第一题
        if let firstQuiz = quizzes.first {
            quizState = QuizState(prompt: firstQuiz.0, options: firstQuiz.1)
            scheduleQuizNotification()
        }
    }

    private func registerStaticCategories() {
        let remember = UNNotificationAction(identifier: ActionID.remember, title: "记住了！", options: [])
        let skip = UNNotificationAction(identifier: ActionID.skip, title: "暂时跳过..", options: [])
        let speak = UNNotificationAction(identifier: ActionID.speak, title: "发音", options: [])

        let studyCategory = UNNotificationCategory(identifier: CategoryID.study,
                                                   actions: [remember, skip, speak],
                                                   intentIdentifiers: [],
                                                   options: [])

        let feedbackCategory = UNNotificationCategory(identifier: CategoryID.feedback,
                                                      actions: [],
                                                      intentIdentifiers: [],
                                                      options: [.customDismissAction])

        staticCategories = [studyCategory, feedbackCategory]
        center.setNotificationCategories(staticCategories)
    }

    private func scheduleNextStudyNotification() {
        guard let session = studySession, let word = session.currentWord else { 
            NSLog("⚠️ scheduleNextStudyNotification: session或word为空")
            return 
        }
        NSLog("📝 显示第 \(session.index + 1) 个单词，共 \(session.words.count) 个")
        studySession = session
        let content = UNMutableNotificationContent()
        content.title = word.displayTitle
        content.subtitle = word.partOfSpeech
        content.body = formattedBody(for: word)
        content.categoryIdentifier = CategoryID.study
        content.sound = .default
        content.userInfo = ["term": word.term]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        center.removePendingNotificationRequests(withIdentifiers: [RequestID.study])
        let request = UNNotificationRequest(identifier: RequestID.study, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                NSLog("调度学习通知失败: \(error)")
            }
        }
    }

    private func scheduleQuizNotification() {
        guard let quizState else { return }
        registerQuizCategory(options: quizState.options)

        let content = UNMutableNotificationContent()
        
        // 如果是测试会话,显示进度
        if let session = quizSession {
            content.title = "随机测试 [\(session.progress)]"
            NSLog("📝 显示测试题 \(session.progress)")
        } else {
            content.title = "随机测试"
        }
        
        content.subtitle = quizState.prompt.meaning
        content.body = "请选择正确的英文释义。"
        content.categoryIdentifier = CategoryID.quiz
        content.sound = .default
        content.userInfo = ["answer": quizState.prompt.term]

        center.removePendingNotificationRequests(withIdentifiers: [RequestID.quiz])
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: RequestID.quiz, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                NSLog("调度测验通知失败: \(error)")
            }
        }
    }

    private func registerQuizCategory(options: [Word]) {
        var actions: [UNNotificationAction] = []
        for (index, option) in options.enumerated() {
            let identifier = "\(ActionID.quizPrefix)\(index)"
            let action = UNNotificationAction(identifier: identifier, title: option.term, options: [])
            actions.append(action)
        }
        let quizCategory = UNNotificationCategory(identifier: CategoryID.quiz,
                                                  actions: actions,
                                                  intentIdentifiers: [],
                                                  options: [])
        var categories = staticCategories
        categories.insert(quizCategory)
        center.setNotificationCategories(categories)
    }

    private func scheduleFeedbackNotification(correct: Bool, answer: Word) {
        let content = UNMutableNotificationContent()
        let symbol = correct ? "✅" : "❌"
        content.title = correct ? "\(symbol) 答对了！" : "\(symbol) 答错了"
        content.body = "正确答案：\(answer.term) - \(answer.meaning)"
        content.categoryIdentifier = CategoryID.feedback
        content.sound = .default

        center.removePendingNotificationRequests(withIdentifiers: [RequestID.feedback])
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: RequestID.feedback, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                NSLog("调度反馈通知失败: \(error)")
            }
        }
    }

    private func formattedBody(for word: Word) -> String {
        if let example = word.example, !example.isEmpty {
            return "\(word.meaning)\n例句：\(example)"
        }
        return word.meaning
    }

    private func postInfoNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "MicroMasters"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = CategoryID.feedback
        let request = UNNotificationRequest(identifier: RequestID.info,
                                            content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false))
        center.add(request) { error in
            if let error {
                NSLog("提示通知失败: \(error)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        defer { completionHandler() }

        switch response.notification.request.identifier {
        case RequestID.study:
            handleStudyResponse(response)
        case RequestID.quiz:
            handleQuizResponse(response)
        default:
            break
        }
    }

    private func handleStudyResponse(_ response: UNNotificationResponse) {
        guard var session = studySession, let word = session.currentWord else { 
            NSLog("⚠️ handleStudyResponse: session或word为空")
            return 
        }

        NSLog("👆 用户响应: \(response.actionIdentifier), 当前: \(session.index + 1)/\(session.words.count)")

        switch response.actionIdentifier {
        case ActionID.remember:
            studyManager.recordResult(for: word, correct: true)
            session.advance()
        case ActionID.skip, UNNotificationDefaultActionIdentifier, UNNotificationDismissActionIdentifier:
            studyManager.recordResult(for: word, correct: false)
            session.advance()
        case ActionID.speak:
            // 发音功能 - 停止之前的发音并开始新的发音
            if speechSynthesizer.isSpeaking {
                speechSynthesizer.stopSpeaking()
            }
            NSLog("🔊 开始发音: \(word.term)")
            speechSynthesizer.startSpeaking(word.term)
            // 不保存 session 状态,保持在当前单词
            // 重新显示当前单词的通知
            scheduleNextStudyNotification()
            return  // 直接返回,不进入下面的逻辑
        default:
            break
        }

        studySession = session

        if session.isCompleted {
            NSLog("✅ 学习完成! 共 \(session.words.count) 个单词")
            studySession = nil
            if let quiz = studyManager.randomQuizQuestion(sourceWords: session.words) {
                quizState = QuizState(prompt: quiz.prompt, options: quiz.options)
                scheduleQuizNotification()
            }
        } else {
            NSLog("➡️ 继续下一个单词")
            scheduleNextStudyNotification()
        }
    }

    private func handleQuizResponse(_ response: UNNotificationResponse) {
        guard let quizState else { return }
        let answer = quizState.prompt

        let selectedIndex: Int?
        if response.actionIdentifier.hasPrefix(ActionID.quizPrefix),
           let value = Int(response.actionIdentifier.replacingOccurrences(of: ActionID.quizPrefix, with: "")) {
            selectedIndex = value
        } else {
            selectedIndex = nil
        }

        let correct: Bool
        if let index = selectedIndex, quizState.options.indices.contains(index) {
            let selectedWord = quizState.options[index]
            correct = (selectedWord.term == answer.term)
        } else {
            correct = false
        }

        scheduleFeedbackNotification(correct: correct, answer: answer)
        self.quizState = nil
        
        // 如果是测试会话,继续下一题
        if var session = quizSession {
            session.advance()
            quizSession = session
            
            if session.isCompleted {
                NSLog("✅ 随机测试完成! 共完成 \(session.quizzes.count) 道题")
                quizSession = nil
            } else if let nextQuiz = session.currentQuiz {
                NSLog("➡️ 继续下一题 (\(session.progress))")
                // 延迟2秒显示下一题,给用户时间看反馈
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.quizState = QuizState(prompt: nextQuiz.0, options: nextQuiz.1)
                    self?.scheduleQuizNotification()
                }
            }
        }
    }
}

