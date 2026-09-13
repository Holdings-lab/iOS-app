import Foundation
import LinkPresentation
import UIKit

/// 기사 URL별 요청 공유와 디코딩된 이미지 캐시. 본문 로딩과 독립적으로 실행한다.
@MainActor
final class NewsroomImageLoader {
    static let shared = NewsroomImageLoader()
    private let session: URLSession
    private let images = NSCache<NSString, UIImage>()
    private var requests: [String: Task<UIImage?, Never>] = [:]
    private var failures: [String: Date] = [:]

    init(session: URLSession = .shared) {
        self.session = session
        images.totalCostLimit = 24 * 1_024 * 1_024
        images.countLimit = 30
    }

    /// 목록 진입 시에는 서버가 제공한 이미지 주소만 미리 받는다.
    /// 기사 메타데이터 폴백은 BrowserEngineKit 프로세스를 띄우므로 실제 상세 화면에서만 실행한다.
    func preload(urls: [URL]) async {
        _ = await image(urls: urls)
    }

    func image(urls: [URL], articleURL: URL? = nil) async -> UIImage? {
        let key = (urls.map(\.absoluteString) + [articleURL?.absoluteString ?? ""]).joined(separator: "\n")
        guard !urls.isEmpty || articleURL != nil else { return nil }
        if let image = images.object(forKey: key as NSString) { return image }
        if let expiry = failures[key], expiry > Date() { return nil }
        if let task = requests[key] { return await task.value }
        let task = Task<UIImage?, Never> {
            for url in urls.prefix(3) {
                if let image = await self.download(url) { return image }
                guard !Task.isCancelled else { return nil }
            }
            // 서버 이미지가 없거나 깨졌다면 해당 원문이 제공하는 대표 이미지를 읽는다.
            guard let articleURL, !Task.isCancelled else { return nil }
            let metadataProvider = LPMetadataProvider()
            metadataProvider.timeout = 6
            metadataProvider.shouldFetchSubresources = true
            do {
                let metadata = try await metadataProvider.startFetchingMetadata(for: articleURL)
                guard let provider = metadata.imageProvider,
                      provider.canLoadObject(ofClass: UIImage.self) else { return nil }
                return await withCheckedContinuation { continuation in
                    _ = provider.loadObject(ofClass: UIImage.self) { object, _ in
                        continuation.resume(returning: object as? UIImage)
                    }
                }
            } catch { return nil }
        }
        requests[key] = task
        let image = await task.value
        requests[key] = nil
        if let image {
            let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
            images.setObject(image, forKey: key as NSString, cost: cost)
        } else {
            failures = failures.filter { $0.value > Date() }
            failures[key] = Date().addingTimeInterval(60)
        }
        return image
    }

    private func download(_ url: URL) async -> UIImage? {
        guard NewsroomRemoteURL.parse(url.absoluteString) != nil else { return nil }
        if let image = images.object(forKey: url.absoluteString as NSString) { return image }
        do {
            let (data, response) = try await session.data(for: URLRequest(url: url, timeoutInterval: 5))
            guard let response = response as? HTTPURLResponse, response.statusCode == 200,
                  response.mimeType?.hasPrefix("image/") == true,
                  data.count <= 8 * 1_024 * 1_024,
                  let image = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 1_000, height: 700)) else { return nil }
            let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? data.count
            images.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
            return image
        } catch { return nil }
    }
}

extension NewsroomTickerDetail {
    var imageCandidates: [URL] {
        // 다른 출처의 사진을 현재 헤드라인 사진으로 쓰지 않는다.
        // 첫 출처에 사진이 없으면 해당 원문의 메타데이터를 조회한다.
        if let primary = sources.first, primary.url != nil {
            return [primary.thumbnailURL].compactMap { $0 }
        }
        return [imageURL ?? sources.first?.thumbnailURL].compactMap { $0 }
            .filter { NewsroomRemoteURL.parse($0.absoluteString) != nil }
    }

    var primaryArticleURL: URL? { sources.compactMap(\.url).first }
}
