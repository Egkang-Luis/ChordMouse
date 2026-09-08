import Foundation

/// The app intentionally follows the system's first preferred language. Korean
/// is used only for a Korean system; every other language uses English.
enum AppText {
    static let isKorean = Locale.preferredLanguages.first?.lowercased().hasPrefix("ko") == true

    static func choose(_ korean: String, _ english: String) -> String {
        isKorean ? korean : english
    }

    static var tooltip: String { choose("ChordMouse — 좌우 버튼을 누른 채 드래그", "ChordMouse — hold both mouse buttons and drag") }
    static var starting: String { choose("시작 중…", "Starting…") }
    static var pause: String { choose("제스처 일시 정지", "Pause gestures") }
    static var resume: String { choose("제스처 다시 켜기", "Resume gestures") }
    static var noGesture: String { choose("아직 실행한 제스처 없음", "No gesture executed yet") }
    static var inputWaiting: String { choose("입력: 대기 중", "Input: waiting") }
    static var swapHorizontal: String { choose("좌/우 데스크탑 방향 바꾸기", "Reverse left/right desktop direction") }
    static var launchAtLogin: String { choose("로그인 시 자동 실행", "Launch at login") }
    static var launchNeedsApproval: String { choose("로그인 시 자동 실행 (승인 필요)", "Launch at login (approval required)") }
    static var help: String { choose("사용 방법 및 권한 안내…", "Usage and permissions…") }
    static var accessibilitySettings: String { choose("손쉬운 사용 설정 열기…", "Open Accessibility Settings…") }
    static var reloadShortcuts: String { choose("현재 시스템 단축키 다시 읽기", "Reload current system shortcuts") }
    static var retry: String { choose("권한 다시 확인 / 시작", "Check permission / start") }
    static var quit: String { choose("ChordMouse 종료", "Quit ChordMouse") }
    static var active: String { choose("제스처 활성화됨", "Gestures active") }
    static var paused: String { choose("일시 정지됨", "Paused") }
    static var needsPermission: String { choose("권한 확인 필요 / 시작되지 않음", "Permission required / not started") }
    static var swapped: String { choose("좌/우 데스크탑 방향: 반전", "Left/right desktop direction: reversed") }
    static var normalDirection: String { choose("좌/우 데스크탑 방향: 기본", "Left/right desktop direction: normal") }
    static var launchDisabled: String { choose("로그인 시 자동 실행: 꺼짐", "Launch at login: off") }
    static var launchApprovalNeeded: String { choose("자동 실행 승인이 필요합니다", "Launch at login requires approval") }
    static var launchEnabled: String { choose("로그인 시 자동 실행: 켜짐", "Launch at login: on") }
    static func launchFailed(_ error: String) -> String { choose("자동 실행 설정 실패: \(error)", "Could not change launch at login: \(error)") }
    static var shortcutsSynced: String { choose("단축키: 시스템 설정 4개 동기화됨", "Shortcuts: synced with all 4 system shortcuts") }
    static func shortcutsMissing(_ names: String) -> String { choose("단축키: 비활성화됨 (\(names))", "Shortcuts: unavailable (\(names))") }
    static func lastGesture(_ direction: Direction) -> String { choose("최근 제스처: \(directionName(direction))", "Last gesture: \(directionName(direction))") }
    static var tapReconnected: String { choose("입력 탭을 다시 연결했습니다", "Input connection restored") }
    static func firstButton(_ button: Int) -> String {
        let name = button == 0 ? choose("좌 버튼", "left button") : choose("우 버튼", "right button")
        return choose("입력: \(name) 감지 — 반대 버튼을 누르세요", "Input: \(name) detected — press the other button")
    }
    static var chordDetected: String { choose("입력: 두 버튼 감지 — 드래그하세요", "Input: both buttons detected — drag") }
    static func gestureExecuted(_ direction: Direction) -> String { choose("입력: \(directionName(direction)) 제스처 실행", "Input: \(directionName(direction)) gesture executed") }

    static func directionName(_ direction: Direction) -> String {
        switch direction {
        case .left: return choose("왼쪽", "Left")
        case .right: return choose("오른쪽", "Right")
        case .up: return choose("위", "Up")
        case .down: return choose("아래", "Down")
        }
    }

    static var helpTitle: String { choose("ChordMouse 사용 방법", "How to use ChordMouse") }
    static var helpMessage: String {
        choose(
            "좌클릭과 우클릭을 230ms 이내에 누른 후, 둘 다 누른 채 드래그하세요.\n\n← 이전 데스크탑   → 다음 데스크탑\n↑ Mission Control   ↓ App Exposé\n\n이동량 35를 넘으면 한 번 실행합니다. 다시 실행하려면 두 버튼을 모두 놓으세요. 움직이지 않고 놓으면 클릭하지 않습니다.\n\n시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 ChordMouse를 허용한 뒤 메뉴의 ‘권한 다시 확인 / 시작’을 누르세요. 필요하면 앱을 다시 실행하세요.\n\n시스템 설정 → 키보드 → 키보드 단축키 → Mission Control에서 단축키를 활성화하세요. 좌우 이동은 데스크탑이 2개 이상 필요합니다. 일반 클릭에는 최대 230ms 지연이 생길 수 있습니다.",
            "Press left and right click within 230 ms, then keep both pressed while dragging.\n\n← Previous desktop   → Next desktop\n↑ Mission Control   ↓ App Exposé\n\nThe action runs once after 35 points of movement. Release both buttons before using another gesture. Releasing without moving does not click.\n\nAllow ChordMouse in System Settings → Privacy & Security → Accessibility, then choose ‘Check permission / start’ from the menu. Restart the app if needed.\n\nEnable the shortcuts in System Settings → Keyboard → Keyboard Shortcuts → Mission Control. Desktop switching needs at least two desktops. Normal clicks can be delayed by up to 230 ms."
        )
    }
    static var ok: String { choose("확인", "OK") }
}
