import Foundation
@preconcurrency import Moya
@preconcurrency import Alamofire

nonisolated struct EndpointTarget: TargetType {
    let endpoint: Endpoint

    var baseURL: URL {
        endpoint.baseURL
    }

    var path: String {
        endpoint.path
    }

    var method: Moya.Method {
        switch endpoint.method {
        case .get:
            return .get
        case .post:
            return .post
        case .put:
            return .put
        case .patch:
            return .patch
        case .delete:
            return .delete
        }
    }

    var task: Moya.Task {
        let parameters = endpoint.queryParameters

        if let body = endpoint.body {
            if parameters.isEmpty {
                return .requestData(body)
            }

            return .requestCompositeData(
                bodyData: body,
                urlParameters: parameters
            )
        }

        if parameters.isEmpty {
            return .requestPlain
        }

        return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
    }

    var headers: [String: String]? {
        endpoint.headers
    }

    var sampleData: Data {
        Data()
    }

    var validationType: ValidationType {
        .successCodes
    }
}
