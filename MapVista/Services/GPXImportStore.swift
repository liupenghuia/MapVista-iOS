// 文件路径: MapVista/Services/GPXImportStore.swift
// 作用: 处理系统打开/分享进来的 GPX 文件，并把解析后的轨迹发布给首页

import Foundation
import Combine

final class GPXImportStore: ObservableObject {
    static let shared = GPXImportStore()

    @Published private(set) var importedTrackDocument: GPXTrackDocument?
    @Published private(set) var importErrorMessage: String?
    @Published private(set) var isImporting = false

    private let parser = GPXParser()
    private var inFlightURL: URL?
    private var lastHandledURL: URL?
    private var lastHandledAt: Date?
    private let duplicateSuppressionWindow: TimeInterval = 2

    func importGPX(from url: URL) {
        let normalizedURL = url.standardizedFileURL

        if shouldIgnoreDuplicate(normalizedURL) {
            return
        }

        guard url.pathExtension.lowercased() == "gpx" else {
            DispatchQueue.main.async {
                self.importErrorMessage = "当前文件不是 GPX 格式。"
            }
            return
        }

        if isImporting, inFlightURL == normalizedURL {
            return
        }

        DispatchQueue.main.async {
            self.isImporting = true
            self.importErrorMessage = nil
            self.inFlightURL = normalizedURL
            self.lastHandledURL = normalizedURL
            self.lastHandledAt = Date()
        }

        DispatchQueue.global(qos: .userInitiated).async { [parser] in
            do {
                let record = try parser.parseTrack(from: normalizedURL)
                let document = GPXTrackDocument(sourceURL: normalizedURL, record: record)
                DispatchQueue.main.async {
                    self.importedTrackDocument = document
                    self.isImporting = false
                    self.inFlightURL = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.importedTrackDocument = nil
                    self.importErrorMessage = error.localizedDescription
                    self.isImporting = false
                    self.inFlightURL = nil
                }
            }
        }
    }

    func clearImportedTrack() {
        importedTrackDocument = nil
        importErrorMessage = nil
        isImporting = false
        inFlightURL = nil
    }

    private func shouldIgnoreDuplicate(_ url: URL) -> Bool {
        guard let lastHandledURL, let lastHandledAt else { return false }
        guard lastHandledURL == url else { return false }
        return Date().timeIntervalSince(lastHandledAt) < duplicateSuppressionWindow
    }
}
