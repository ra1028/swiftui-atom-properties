import AVFAudio

protocol AudioSessionProtocol {
    var recordPermission: AVAudioSession.RecordPermission { get }

    func requestRecordPermissionOnMain(_ response: @escaping (Bool) -> Void)
    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws
    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws
}

extension AVAudioSession: AudioSessionProtocol {
    func requestRecordPermissionOnMain(_ response: @escaping (Bool) -> Void) {
        requestRecordPermission { isGranted in
            Task { @MainActor in
                response(isGranted)
            }
        }
    }
}

final class MockAudioSession: AudioSessionProtocol {
    var requestRecordPermissionResponse: ((Bool) -> Void)?
    var isActive = false
    var currentCategory: AVAudioSession.Category?
    var currentMode: AVAudioSession.Mode?
    var currentOptions: AVAudioSession.CategoryOptions?

    var recordPermission = AVAudioSession.RecordPermission.granted

    func requestRecordPermissionOnMain(_ response: @escaping (Bool) -> Void) {
        requestRecordPermissionResponse = response
    }

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
        isActive = active
    }

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws {
        currentCategory = category
        currentMode = mode
        currentOptions = options
    }
}
