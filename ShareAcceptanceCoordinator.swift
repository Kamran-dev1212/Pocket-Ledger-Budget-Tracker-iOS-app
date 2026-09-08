import Foundation

final class ShareAcceptanceCoordinator: ObservableObject {

    static let shared = ShareAcceptanceCoordinator()

    private init() {}

    enum Result {
        case success(groupName: String)
        case failure(message: String)
    }

    @Published var lastResult: Result?

}
