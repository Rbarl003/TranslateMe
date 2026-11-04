//
//  TranslationMeView.swift
//  Firechat
//
//  TranslationMe home screen: translate text between a variety of languages
//  and keep a local history.
//

import SwiftUI
import Translation

// MARK: - Language catalog

struct TranslationLanguage: Identifiable, Hashable {
    let id: String // BCP-47 identifier understood by Locale.Language.
    let displayName: String
    let flag: String

    var locale: Locale.Language { Locale.Language(identifier: id) }
}

extension TranslationLanguage {
    static let english = TranslationLanguage(id: "en", displayName: "English", flag: "🇺🇸")
    static let spanish = TranslationLanguage(id: "es", displayName: "Spanish", flag: "🇪🇸")
    static let french = TranslationLanguage(id: "fr", displayName: "French", flag: "🇫🇷")
    static let german = TranslationLanguage(id: "de", displayName: "German", flag: "🇩🇪")
    static let italian = TranslationLanguage(id: "it", displayName: "Italian", flag: "🇮🇹")
    static let portuguese = TranslationLanguage(id: "pt-BR", displayName: "Portuguese", flag: "🇧🇷")
    static let japanese = TranslationLanguage(id: "ja", displayName: "Japanese", flag: "🇯🇵")
    static let korean = TranslationLanguage(id: "ko", displayName: "Korean", flag: "🇰🇷")
    static let chineseSimplified = TranslationLanguage(id: "zh-Hans", displayName: "Chinese", flag: "🇨🇳")
    static let arabic = TranslationLanguage(id: "ar", displayName: "Arabic", flag: "🇸🇦")
    static let hindi = TranslationLanguage(id: "hi", displayName: "Hindi", flag: "🇮🇳")
    static let russian = TranslationLanguage(id: "ru", displayName: "Russian", flag: "🇷🇺")

    /// The full set of languages offered in the picker menus.
    static let all: [TranslationLanguage] = [
        .english, .spanish, .french, .german, .italian, .portuguese,
        .japanese, .korean, .chineseSimplified, .arabic, .hindi, .russian
    ]

    /// Looks up a catalog entry for a raw BCP-47 code (e.g. from a detected
    /// source language), falling back gracefully if it isn't in the catalog.
    static func lookup(code: String?) -> TranslationLanguage? {
        guard let code, !code.isEmpty else { return nil }
        let normalized = code.lowercased()
        return all.first {
            $0.id.lowercased() == normalized ||
            $0.id.split(separator: "-").first?.lowercased() == normalized
        }
    }
}

// MARK: - History model

struct TranslationHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let sourceText: String
    let translatedText: String
    let sourceLanguageCode: String
    let targetLanguageCode: String
    let date: Date

    init(
        id: UUID = UUID(),
        sourceText: String,
        translatedText: String,
        sourceLanguageCode: String,
        targetLanguageCode: String,
        date: Date = Date()
    ) {
        self.id = id
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLanguageCode = sourceLanguageCode
        self.targetLanguageCode = targetLanguageCode
        self.date = date
    }

    var sourceLanguageDisplay: String {
        TranslationLanguage.lookup(code: sourceLanguageCode)
            .map { "\($0.flag) \($0.displayName)" } ?? sourceLanguageCode.uppercased()
    }

    var targetLanguageDisplay: String {
        TranslationLanguage.lookup(code: targetLanguageCode)
            .map { "\($0.flag) \($0.displayName)" } ?? targetLanguageCode.uppercased()
    }
}

// MARK: - History store

/// Keeps the translation history in memory and persists it to UserDefaults
/// so it survives relaunching the app, until the user erases it.
@MainActor
@Observable
final class TranslationHistoryStore {
    private(set) var items: [TranslationHistoryItem] = []

    private let storageKey = "com.firechat.translationHistory"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func add(sourceText: String, translatedText: String, sourceLanguageCode: String, targetLanguageCode: String) {
        let item = TranslationHistoryItem(
            sourceText: sourceText,
            translatedText: translatedText,
            sourceLanguageCode: sourceLanguageCode,
            targetLanguageCode: targetLanguageCode
        )
        items.insert(item, at: 0) // Newest first.
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([TranslationHistoryItem].self, from: data) else {
            return
        }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

// MARK: - Reusable flair components

/// A tap-friendly button style with a soft spring "bounce" on press.
private struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A pill-shaped menu button used for the "From" and "To" language pickers.
private struct LanguagePickerButton: View {
    let title: String
    let selection: TranslationLanguage?
    let options: [TranslationLanguage]
    let allowsAutoDetect: Bool
    let onSelect: (TranslationLanguage?) -> Void

    var body: some View {
        Menu {
            if allowsAutoDetect {
                Button {
                    onSelect(nil)
                } label: {
                    Label("Detect Language", systemImage: "wand.and.stars")
                }
                Divider()
            }
            ForEach(options) { language in
                Button {
                    onSelect(language)
                } label: {
                    Text("\(language.flag) \(language.displayName)")
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(selection?.flag ?? "✨")
                    Text(selection?.displayName ?? "Detect Language")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
}

/// The circular gradient button between the two language pickers that swaps them.
private struct SwapLanguagesButton: View {
    let isEnabled: Bool
    let action: () -> Void

    @State private var rotation: Double = 0

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                rotation += 180
            }
            action()
        } label: {
            Image(systemName: "arrow.left.arrow.right")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(
                        isEnabled
                            ? AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(Color.gray.opacity(0.35))
                    )
                )
                .rotationEffect(.degrees(rotation))
        }
        .disabled(!isEnabled)
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Swap languages")
    }
}

// MARK: - Main view

struct TranslationMeView: View {
    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    @State private var textToTranslate: String = ""
    @State private var configuration: TranslationSession.Configuration?
    @State private var errorMessage: String?
    @State private var isTranslating: Bool = false
    @State private var historyStore = TranslationHistoryStore()

    @State private var sourceLanguage: TranslationLanguage? // nil = auto-detect
    @State private var targetLanguage: TranslationLanguage = .spanish

    @State private var globeRotation: Double = 0

    private var trimmedInput: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    languageSelectionRow
                    inputSection
                    translateButton
                    translationOutputSection
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }

                    Divider()

                    historySection
                }
                .padding()
            }
        }
        .translationTask(configuration) { session in
            isTranslating = true
            defer { isTranslating = false }
            do {
                let response = try await session.translate(textToTranslate)
                let sourceCode = response.sourceLanguage.languageCode?.identifier ?? "?"
                let targetCode = response.targetLanguage.languageCode?.identifier ?? "?"
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    translatedText = response.targetText
                    historyStore.add(
                        sourceText: textToTranslate,
                        translatedText: response.targetText,
                        sourceLanguageCode: sourceCode,
                        targetLanguageCode: targetCode
                    )
                }
                errorMessage = nil
            } catch {
                errorMessage = "Translation failed. Please try again."
            }
        }
    }

    // MARK: Sections

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.08), Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 34))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .rotationEffect(.degrees(globeRotation))
                .onAppear {
                    withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                        globeRotation = 360
                    }
                }

            Text("Talk Freely")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple, .pink], startPoint: .leading, endPoint: .trailing)
                )
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var languageSelectionRow: some View {
        HStack(spacing: 10) {
            LanguagePickerButton(
                title: "From",
                selection: sourceLanguage,
                options: TranslationLanguage.all,
                allowsAutoDetect: true
            ) { sourceLanguage = $0 }

            SwapLanguagesButton(isEnabled: sourceLanguage != nil, action: swapLanguages)

            LanguagePickerButton(
                title: "To",
                selection: targetLanguage,
                options: TranslationLanguage.all,
                allowsAutoDetect: false
            ) { if let language = $0 { targetLanguage = language } }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter text")
                .font(.headline)
            TextField("Type a word, phrase, or sentence", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.thinMaterial))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        }
    }

    private var translateButton: some View {
        Button {
            translate()
        } label: {
            HStack(spacing: 8) {
                if isTranslating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                }
                Text(isTranslating ? "Translating…" : "Translate")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(
                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .purple.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(trimmedInput.isEmpty || isTranslating)
        .opacity(trimmedInput.isEmpty ? 0.6 : 1)
    }

    private var translationOutputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Translation")
                    .font(.headline)
                Spacer()
                if !translatedText.isEmpty {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            Text(translatedText.isEmpty ? "Your translation will appear here." : translatedText)
                .foregroundStyle(translatedText.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .topLeading)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.thinMaterial))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            translatedText.isEmpty
                                ? AnyShapeStyle(Color.clear)
                                : AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)),
                            lineWidth: 1.5
                        )
                )
                .animation(.easeInOut, value: translatedText)
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("History", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                Spacer()
                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        historyStore.clear()
                    }
                } label: {
                    Label("Clear", systemImage: "trash")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(historyStore.items.isEmpty)
            }

            if historyStore.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.bubble")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No translations yet.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(historyStore.items) { item in
                        historyRow(for: item)
                    }
                }
            }
        }
    }

    private func historyRow(for item: TranslationHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(item.sourceLanguageDisplay)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                Text(item.targetLanguageDisplay)
                Spacer()
                Text(item.date, style: .time)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)

            Text(item.sourceText)
                .font(.subheadline)
            Text(item.translatedText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: Actions

    private func translate() {
        guard !trimmedInput.isEmpty else { return }
        textToTranslate = trimmedInput
        errorMessage = nil

        let desiredSource = sourceLanguage?.locale
        let desiredTarget = targetLanguage.locale

        if let current = configuration, current.source == desiredSource, current.target == desiredTarget {
            configuration?.invalidate()
        } else {
            configuration = TranslationSession.Configuration(source: desiredSource, target: desiredTarget)
        }
    }

    private func swapLanguages() {
        guard let currentSource = sourceLanguage else { return }
        let newTarget = currentSource
        let newSource = targetLanguage
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            sourceLanguage = newSource
            targetLanguage = newTarget
            let oldInput = inputText
            inputText = translatedText
            translatedText = oldInput
        }
    }
}

#Preview {
    TranslationMeView()
}
