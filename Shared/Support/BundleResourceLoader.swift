import Foundation

enum BundleResourceLoader {
    static func data(named name: String, extension fileExtension: String, in bundle: Bundle = .main) throws -> Data {
        let locations: [URL?] = [
            bundle.url(forResource: name, withExtension: fileExtension, subdirectory: "Resources"),
            bundle.url(forResource: name, withExtension: fileExtension)
        ]

        guard let url = locations.compactMap({ $0 }).first else {
            throw ResourceError.notFound("\(name).\(fileExtension)")
        }
        return try Data(contentsOf: url)
    }

    enum ResourceError: LocalizedError {
        case notFound(String)

        var errorDescription: String? {
            switch self {
            case .notFound(let filename):
                return "找不到本地资源 \(filename)。"
            }
        }
    }
}
