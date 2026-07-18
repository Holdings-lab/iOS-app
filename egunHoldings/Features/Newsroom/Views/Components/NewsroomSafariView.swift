import SwiftUI
import SafariServices

/// 근거 기사용 인앱 브라우저 (§3, §4). 앱을 벗어나지 않고 원문을 확인하고,
/// 닫으면 다이제스트 상세의 스크롤 위치·번역 펼침 상태가 그대로 유지된다.
struct NewsroomSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct NewsroomSafariDestination: Identifiable, Equatable {
    let url: URL

    var id: String { url.absoluteString }
}
