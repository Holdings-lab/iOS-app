import Combine
import SwiftUI

@MainActor
final class AssetViewModel: ObservableObject {
    @Published var selectedSegment: AssetSegment = .overview
    @Published var isBrokerConnectionPresented = false
    @Published var semiconductorTarget: Double = 32
    @Published var bondTarget: Double = 24
    @Published var energyTarget: Double = 18
    @Published var cashTarget: Double = 26

    let dashboard: AssetDashboard

    init(repository: AssetRepositoryProtocol? = nil) {
        let repository = repository ?? MockAssetRepository()
        dashboard = repository.fetchDashboard()
    }

    func selectSegment(_ segment: AssetSegment) {
        selectedSegment = segment
    }

    func presentBrokerConnection() {
        isBrokerConnectionPresented = true
    }

    func dismissBrokerConnection() {
        isBrokerConnectionPresented = false
    }
}
