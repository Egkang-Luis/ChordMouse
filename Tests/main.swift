import Foundation

var checks = 0
func check(_ condition: Bool, _ message: String) { checks += 1; if !condition { fatalError(message) } }
func chord(_ first: Int = 0) -> GestureRecognizer {
    let r = GestureRecognizer()
    check(r.handle(.down(first), now: 0).consume, "first button is held")
    let result = r.handle(.down(1 - first), now: 0.03)
    check(result.consume && result.discard, "second button begins chord")
    return r
}
for (dx, dy, expected) in [(70.0, 0.0, GestureTrigger.dragRight), (-70, 0, .dragLeft), (0, -70, .dragUp), (0, 70, .dragDown)] {
    let r = chord()
    check(r.handle(.move(dx, dy), now: 0.04).trigger == expected, "direction trigger")
    check(r.handle(.move(dx, dy), now: 0.05).trigger == nil, "only one direction action")
}
do {
    let r = chord(0)
    let firstUp = r.handle(.up(1), now: 0.04)
    check(firstUp.trigger == nil, "wait for a possible double click")
    check(r.expire(now: 0.33).trigger == .leftHoldRightClick, "left hold right click")
}
do {
    let r = chord(0)
    _ = r.handle(.up(1), now: 0.04)
    let second = r.handle(.down(1), now: 0.12)
    check(second.trigger == .leftHoldRightDoubleClick, "left hold right double click")
}
do {
    let r = chord(1)
    _ = r.handle(.up(0), now: 0.04)
    check(r.expire(now: 0.33).trigger == .rightHoldLeftClick, "right hold left click")
}
do {
    let r = chord(0)
    _ = r.handle(.up(1), now: 0.04)
    _ = r.handle(.up(0), now: 0.05)
    _ = r.handle(.down(0), now: 0.42)
    check(r.handle(.down(1), now: 0.45).trigger == .leftRightLeftRight, "left-right-left-right is recognized")
}
do {
    let r = chord(1)
    _ = r.handle(.up(0), now: 0.04)
    _ = r.handle(.up(1), now: 0.05)
    _ = r.handle(.down(1), now: 0.42)
    check(r.handle(.down(0), now: 0.45).trigger == .rightLeftRightLeft, "right-left-right-left is recognized")
}
do {
    let r = chord(0)
    _ = r.handle(.up(1), now: 0.04)
    _ = r.handle(.up(0), now: 0.05)
    _ = r.handle(.down(1), now: 0.42)
    check(r.handle(.down(0), now: 0.45).trigger == nil, "two-button double-click no longer has an action")
}
do {
    let r = chord(0)
    _ = r.handle(.up(1), now: 0.04)
    check(r.expire(now: 0.33).trigger == .leftHoldRightClick, "first single click")
    check(r.handle(.down(1), now: 0.40).trigger == .leftHoldRightClick, "single click repeats while primary is held")
    _ = r.handle(.up(1), now: 0.41)
    check(r.handle(.down(1), now: 0.45).trigger == .leftHoldRightClick, "subsequent single click repeats")
}
do {
    let r = chord(1)
    _ = r.handle(.up(0), now: 0.04)
    check(r.handle(.down(0), now: 0.12).trigger == .rightHoldLeftDoubleClick, "first double click")
    _ = r.handle(.up(0), now: 0.13)
    check(r.handle(.down(0), now: 0.20).trigger == nil, "next double click waits for its second press")
    _ = r.handle(.up(0), now: 0.21)
    check(r.handle(.down(0), now: 0.28).trigger == .rightHoldLeftDoubleClick, "double click repeats while primary is held")
}
do {
    let r = GestureRecognizer()
    _ = r.handle(.down(0), now: 0)
    check(r.expire(now: 0.231).flush, "normal click restores after chord window")
}
do {
    let r = GestureRecognizer()
    _ = r.handle(.down(0), now: 0)
    let result = r.handle(.up(0), now: 0.08)
    check(result.consume && result.flush, "normal short click replays its matching mouse-up")
}
do {
    let r = GestureRecognizer()
    _ = r.handle(.down(0), now: 0)
    let result = r.handle(.move(21, 0), now: 0.04)
    check(result.consume && result.flush, "normal click-drag replays its buffered down and drag input together")
}
print("PASS: \(checks) gesture checks")
