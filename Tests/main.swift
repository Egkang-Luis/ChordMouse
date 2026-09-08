import Foundation
var checks = 0
func check(_ condition: Bool, _ message: String) {
    checks += 1
    if !condition { fatalError(message) }
}
func chord(_ first: Int = 0) -> GestureRecognizer {
    let r = GestureRecognizer()
    check(r.handle(.down(first), now: 0).consume, "first down buffered")
    let d = r.handle(.down(1-first), now: 0.03)
    check(d.consume && d.discard && !d.flush, "chord consumes both downs")
    return r
}
for (dx, dy, expected) in [(70.0, 0.0, Direction.right), (-70, 0, .left), (0, -70, .up), (0, 70, .down)] {
    for first in [0, 1] {
        let r = chord(first)
        check(r.handle(.move(dx/3, dy/3), now: 0.04).direction == nil, "below threshold")
        check(r.handle(.move(dx * 2 / 3, dy * 2 / 3), now: 0.05).direction == expected, "four direction mapping")
        check(r.handle(.move(dx*3, dy*3), now: 0.06).direction == nil, "only once")
        check(r.handle(.up(first), now: 0.07).consume, "first up swallowed")
        check(r.handle(.move(100, 100), now: 0.08).direction == nil, "no action after release")
        check(r.handle(.up(1-first), now: 0.09).consume && r.idle, "drain second up")
    }
}
do {
    let r = GestureRecognizer()
    _ = r.handle(.down(0), now: 0)
    let up = r.handle(.up(0), now: 0.01)
    check(up.flush && !up.consume && r.idle, "quick click replays down before up")
    _ = r.handle(.down(0), now: 0.02)
    check(r.handle(.up(0), now: 0.03).flush, "double click sequence preserved")
}
do {
    let r = GestureRecognizer()
    _ = r.handle(.down(1), now: 0)
    check(!r.expire(now: 0.229), "wait until deadline")
    check(r.expire(now: 0.231), "timer restores held click")
    check(!r.handle(.down(0), now: 0.24).consume, "late chord passes through")
    check(!r.handle(.up(0), now: 0.25).consume, "late up passes")
    _ = r.handle(.up(1), now: 0.26)
    check(r.idle, "late chord resets")
}
do {
    let r = GestureRecognizer()
    _ = r.handle(.down(0), now: 0)
    check(r.handle(.move(10, 0), now: 0.01).consume, "small motion buffered")
    let d = r.handle(.move(11, 0), now: 0.02)
    check(d.flush && !d.consume, "ordinary drag released early")
    check(!r.handle(.down(1), now: 0.03).consume, "drag cannot become chord")
}
do {
    let r = chord()
    check(r.handle(.up(0), now: 0.04).consume, "cancel chord")
    _ = r.handle(.down(0), now: 0.05)
    check(r.handle(.move(200, 0), now: 0.06).direction == nil, "repress does not rearm")
    _ = r.handle(.up(0), now: 0.07)
    _ = r.handle(.up(1), now: 0.08)
    check(r.idle, "all released rearm")
}
do {
    let r = GestureRecognizer()
    _ = r.handle(.down(0), now: 0)
    let d = r.handle(.down(1), now: 0.230)
    check(d.flush && !d.consume, "exact deadline is late")
}
do {
    let r = GestureRecognizer()
    _ = r.handle(.down(0), now: 0)
    check(r.handle(.other, now: 0.01).flush, "scroll flushes pending input")
}
print("PASS: \(checks) state-machine checks")
