# 버전 기록

[← ChordMouse 첫 화면](README.md)

## 0.1.0 — 첫 배포 준비 중

아래 내용은 로컬 빌드 v0.1.0 기준입니다. GitHub Release와 설치 파일은 아직 게시되지 않았습니다.

### 주요 기능

- 왼쪽·오른쪽 마우스 버튼 조합으로 네 방향 제스처 실행
- 데스크탑 전환, Mission Control, 현재 앱의 윈도우 보기
- 메뉴바에서 시작, 일시 정지, 권한 상태 확인
- macOS에 설정된 Mission Control 단축키 읽기
- 좌우 데스크탑 방향 전환
- 로그인 시 자동 실행

### 준비된 빌드

- 파일명: `ChordMouse-0.1.0-macOS-arm64.zip`
- 지원 환경: macOS 13 이상, Apple Silicon
- 서명 상태: 로컬 ad-hoc 서명
- Developer ID 서명 및 Apple 공증: 미완료

### 알려진 한계

- 일반 클릭에 최대 약 230ms의 대기 시간 발생 가능
- 연속 스와이프 애니메이션 및 관성 동작 미지원
- 다른 마우스 유틸리티와의 충돌 가능
- Intel 배포 파일 미제공
