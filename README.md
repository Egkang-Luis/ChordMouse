# ChordMouse

macOS 13 이상에서 동작하는 메뉴 막대 앱이며 손쉬운 사용 권한이 필요합니다.

## 실행

압축을 푼 뒤 `build/ChordMouse.app`을 실행합니다. 메뉴에서 **Check permission / start**를 누르고, 시스템 설정의 손쉬운 사용에서 ChordMouse를 허용하세요.

## 기본 동작

| 입력 | 기본 동작 |
|---|---|
| 좌+우 버튼 유지 후 왼쪽/오른쪽 드래그 | 다음/이전 데스크탑 |
| 좌+우 버튼 유지 후 위/아래 드래그 | Mission Control / App Exposé |
| 좌 버튼 유지 + 우 클릭/더블 클릭 | 앞으로 가기 / 다음 탭 |
| 우 버튼 유지 + 좌 클릭/더블 클릭 | 뒤로 가기 / 이전 탭 |
| 좌→우→좌→우 빠른 클릭 | Focus Zoom |
| 우→좌→우→좌 빠른 클릭 | Zoom Out |
| 휠 버튼 유지 + 위/아래 스크롤 | 볼륨 내리기 / 올리기 |

좌 또는 우 버튼을 계속 누른 상태에서는, 처음 실행한 클릭 방식이 반복됩니다. 예를 들어 **좌 버튼 유지 + 우 클릭**에 앞으로 가기를 연결하면 첫 조합 뒤에는 좌 버튼을 계속 누른 채 우 버튼만 다시 클릭해도 앞으로 가기가 반복됩니다. 더블 클릭으로 시작한 경우에는 이후 더블 클릭마다 반복됩니다.

메뉴의 **Open Gesture Settings… / 제스처 설정 열기…**를 누르면 별도 설정 창이 열립니다. 각 행의 오른쪽 메뉴에서 입력마다 다음 중 하나를 고를 수 있으며, 선택은 즉시 저장됩니다.

- Volume Up / Down
- Zoom In / Out
- Brightness Up / Down
- Next / Previous Tab
- Next / Previous Desktop
- Next / Previous Track
- Back / Forward (Safari·Finder: Command + [ / Command + ])
- Focus Zoom (문서 확대: Command + plus)
- Undo / Redo
- Mission Control
- App Exposé

Mission Control, App Exposé, 데스크탑 전환은 현재 macOS 키보드 단축키를 읽어 실행합니다. 해당 단축키를 시스템 설정에서 활성화해야 합니다.

메뉴의 **Launch at login / 로그인 시 자동 실행**으로 로그인 시 실행을 켜거나 끌 수 있습니다. macOS가 별도 승인을 요구하면 로그인 항목 설정 화면이 열립니다.

## 주의사항

- 두 버튼 드래그는 처음 두 버튼을 230ms 안에 눌러야 기존과 같은 방식으로 가장 안정적으로 동작합니다.
- 버튼 유지 클릭은 더블 클릭 구분을 위해 약 280ms 뒤에 단일 클릭 동작을 실행합니다.
- 휠 버튼을 누른 상태의 스크롤은 매 스크롤 입력마다 연결된 동작을 한 번 실행합니다.
- Focus Zoom은 Preview의 PDF, Safari 등에서 쓰는 표준 문서 확대 단축키(Command + plus)를 보냅니다. 앱이 이 단축키를 지원하지 않으면 별도 Zoom In/Out 동작을 선택하세요.
- 순서형 빠른 클릭은 첫 조합을 모두 놓은 뒤 0.55초 안에 같은 순서로 두 번째 조합을 시작하면 인식합니다.
- 볼륨·밝기·음악 키는 Mac 모델이나 보안 설정, 실행 중인 앱에 따라 macOS가 차단하거나 다르게 처리할 수 있습니다.

## 빌드와 검증

```sh
./test.sh
./build.sh
```

`test.sh`는 확장 입력 상태 머신을 확인합니다. 실제 앱에서는 권한을 부여한 뒤 Finder, 브라우저, 음악 앱에서 각각 확인하세요.
