import Foundation

/// 개발 중 버전 다운그레이드 크래시를 방지하기 위한 SwiftData / Core Data 스타일 저장소 헬퍼입니다.
/// 
/// SwiftData ModelContainer 생성 시, 버전 다운그레이드 오류가 발생하면 저장소 파일을 삭제하여 재생성하도록 합니다.
/// 아래 예시처럼 사용하세요.
///
/// 예시 (SwiftData ModelContainer 생성 시):
/// let storeURL = PersistentStoreRecovery.debugStoreURL(baseName: "Notes")
/// do {
///   let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(url: storeURL)])
/// } catch {
///   // 버전 다운그레이드 에러 발생 시 정리 후 재시도
///   PersistentStoreRecovery.removeStoreIfIncompatible(at: storeURL)
///   let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(url: storeURL)])
/// }
public enum PersistentStoreRecovery {
    /// 개발/배포 환경에 따라 Application Support 내에 저장소 URL을 생성합니다.
    /// 저장소 파일명에 빌드 구성 및 환경변수 STORE_SCHEMA_VERSION 값이 포함됩니다.
    /// - Parameter baseName: 저장소 기본 이름
    /// - Returns: 저장소 파일 URL
    public static func debugStoreURL(baseName: String) -> URL {
        let fileManager = FileManager.default
        let appSupportURLs = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let appSupportURL = appSupportURLs.first else {
            fatalError("Unable to access Application Support directory")
        }

        let storeDirectory = appSupportURL.appendingPathComponent("CoteStore", isDirectory: true)

        if !fileManager.fileExists(atPath: storeDirectory.path) {
            do {
                try fileManager.createDirectory(at: storeDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("Failed to create CoteStore directory: \(error)")
            }
        }

        #if DEBUG
        let buildSuffix = "debug"
        #elseif RELEASE
        let buildSuffix = "release"
        #else
        let buildSuffix = "prod"
        #endif

        var fileName = "\(baseName)-\(buildSuffix)"
        if let version = ProcessInfo.processInfo.environment["STORE_SCHEMA_VERSION"], !version.isEmpty {
            fileName += "-v\(version)"
        }
        fileName += ".sqlite"

        return storeDirectory.appendingPathComponent(fileName, isDirectory: false)
    }

    /// 초기화 실패 중 버전 다운그레이드 오류 시, 저장소 파일과 관련 임시 파일(-wal, -shm)을 삭제합니다.
    /// - Parameter url: 삭제할 저장소 파일 URL
    public static func removeStoreIfIncompatible(at url: URL) {
        let fileManager = FileManager.default
        let pathsToRemove = [
            url,
            url.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent + "-wal"),
            url.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent + "-shm")
        ]

        for path in pathsToRemove {
            if fileManager.fileExists(atPath: path.path) {
                do {
                    try fileManager.removeItem(at: path)
                } catch {
                    // 무시: 삭제 실패해도 진행
                }
            }
        }
    }
}
