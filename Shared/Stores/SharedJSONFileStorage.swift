import Darwin
import Foundation

final class SharedJSONFileStorage<Value: Codable>: @unchecked Sendable {
    private enum Backend {
        case file(dataURL: URL, lockURL: URL)
        case defaults(UserDefaults, key: String, lockURL: URL?)
    }

    private let backend: Backend
    private let legacyDefaults: UserDefaults?
    private let legacyKey: String?
    private let processLock = NSLock()

    init(
        fileName: String,
        defaultsKey: String,
        defaults: UserDefaults? = nil,
        lockURL: URL? = nil,
        legacyDefaults: UserDefaults? = nil,
        legacyKey: String? = nil
    ) {
        self.legacyDefaults = legacyDefaults
        self.legacyKey = legacyKey

        if let defaults {
            backend = .defaults(defaults, key: defaultsKey, lockURL: lockURL)
        } else if let directory = SharedConstants.applicationSupportDirectoryURL() {
            backend = .file(
                dataURL: directory.appendingPathComponent(fileName, isDirectory: false),
                lockURL: directory.appendingPathComponent("\(fileName).lock", isDirectory: false)
            )
        } else {
            backend = .defaults(
                SharedConstants.stateDefaults(),
                key: defaultsKey,
                lockURL: SharedConstants.defaultsStorageLockURL()
            )
        }
    }

    func read() -> Value? {
        withExclusiveAccess { readUnlocked() }
    }

    @discardableResult
    func update(_ transform: (Value?) -> Value) -> Value {
        withExclusiveAccess {
            let updated = transform(readUnlocked())
            saveUnlocked(updated)
            return updated
        }
    }

    @discardableResult
    func updateIfNeeded(
        _ transform: (Value?) -> (value: Value, shouldSave: Bool)
    ) -> Value {
        withExclusiveAccess {
            let result = transform(readUnlocked())
            if result.shouldSave {
                saveUnlocked(result.value)
            }
            return result.value
        }
    }

    private func withExclusiveAccess<Result>(_ operation: () -> Result) -> Result {
        processLock.lock()
        defer { processLock.unlock() }

        let lockURL: URL?
        switch backend {
        case .file(_, let fileLockURL):
            lockURL = fileLockURL
        case .defaults(_, _, let defaultsLockURL):
            lockURL = defaultsLockURL
        }

        guard let lockURL else {
            return operation()
        }

        let descriptor = open(lockURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { return operation() }
        defer { close(descriptor) }

        guard flock(descriptor, LOCK_EX) == 0 else { return operation() }
        defer { flock(descriptor, LOCK_UN) }
        return operation()
    }

    private func readUnlocked() -> Value? {
        let data: Data?
        switch backend {
        case .file(let dataURL, _):
            data = try? Data(contentsOf: dataURL)
        case .defaults(let defaults, let key, _):
            defaults.synchronize()
            data = defaults.data(forKey: key)
        }

        if let data, let decoded = try? JSONDecoder().decode(Value.self, from: data) {
            return decoded
        }

        guard let legacyDefaults,
              let legacyKey,
              let legacyData = legacyDefaults.data(forKey: legacyKey) else {
            return nil
        }
        return try? JSONDecoder().decode(Value.self, from: legacyData)
    }

    private func saveUnlocked(_ value: Value) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        switch backend {
        case .file(let dataURL, _):
            try? data.write(to: dataURL, options: .atomic)
        case .defaults(let defaults, let key, _):
            defaults.set(data, forKey: key)
            defaults.synchronize()
        }

        if let legacyDefaults, let legacyKey {
            legacyDefaults.removeObject(forKey: legacyKey)
        }
    }
}
