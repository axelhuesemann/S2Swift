//
//  Rect.swift
//  Sphere2
//

import Foundation

// package r2
// import fmt, r1


// R2Point represents a point in ℝ².
struct R2Point: Equatable, CustomStringConvertible {

  //
  let x: Double
  let y: Double

  init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }

  // MARK: protocols

  static func ==(lhs: R2Point, rhs: R2Point) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
  }
  
  var description: String {
    return String(format: "[%f, %f]", x, y)
  }
  
}

// R2Rect represents a closed axis-aligned rectangle in the (x,y) plane.

struct R2Rect: Equatable, CustomStringConvertible {
  let x: R1Interval
  let y: R1Interval
  
  // MARK: inits / factory
  
  init(x: R1Interval, y: R1Interval) {
    self.x = x
    self.y = y
  }
  
  // RectFromPoints constructs a rect that contains the given points.
  init(p0: R2Point, p1: R2Point) {
    let x = R1Interval(lo: p0.x, hi: p1.x)
    let y = R1Interval(lo: p0.y, hi: p1.y)
    self.init(x: x, y: y)
  }
  
//  // RectFromPoints constructs a rect that contains the given points.
//  init(ps: [R2Point]) {
//    // Because the default value on interval is 0,0, we need to manually
//    // define the interval from the first point passed in as our starting
//    // interval, otherwise we end up with the case of passing in
//    // R2Point{0.2, 0.3} and getting the starting Rect of {0, 0.2}, {0, 0.3}
//    // instead of the Rect {0.2, 0.2}, {0.3, 0.3} which is not correct.
//    if ps.count == 0 {
//      return R2Rect.empty
//    }
//  
//    let x = R1Interval(lo: p[0].x, hi: p[0].x)
//    let y = R1Interval(lo: p[1].y, hi: p[1].y)
//    self.init(x: x, y: y)
//
////    for _, p := range pts[1:] {
////      r = AddPoint(p)
////    }
//  }

  // RectFromCenterSize constructs a rectangle with the given center and size.
  // Both dimensions of size must be non-negative.
  init(center: R2Point, size: R2Point) {
    let x = R1Interval(lo: center.x - size.x/2, hi: center.x + size.x/2)
    let y = R1Interval(lo: center.y - size.y/2, hi: center.y + size.y/2)
    self.init(x: x, y: y)
  }

  // EmptyRect constructs the canonical empty rectangle. Use IsEmpty() to test
  // for empty rectangles, since they have more than one representation. A Rect
  // is not the same as the EmptyRect.
  static let empty = R2Rect(x: R1Interval.empty, y: R1Interval.empty)

  // MARK: protocols

  static func ==(lhs: R2Rect, rhs: R2Rect) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
  }

  var description: String {
    return "X \(x), Y \(y)"
  }
  
  // MARK: tests 
  
  // IsValid reports whether the rectangle is valid.
  // This requires the width to be empty iff the height is empty.
  func isValid() -> Bool {
    return x.isEmpty() == y.isEmpty()
  }

  // IsEmpty reports whether the rectangle is empty.
  func isEmpty() -> Bool {
    return x.isEmpty()
  }

  // ApproxEquals returns true if the x- and y-intervals of the two rectangles are
  // the same up to the given tolerance.
  func approxEquals(_ rect: R2Rect) -> Bool {
    return x.approxEquals(rect.x) && y.approxEquals(rect.y)
  }
  
  // MARK: computed members
  
  // Vertices returns all four vertices of the rectangle. Vertices are returned in
  // CCW direction starting with the lower left corner.
  func vertices() -> [R2Point] {
    return [
      R2Point(x: x.lo, y: y.lo),
      R2Point(x: x.hi, y: y.lo),
      R2Point(x: x.hi, y: y.hi),
      R2Point(x: x.lo, y: y.hi)]
  }

  // Center returns the center of the rectangle in (x,y)-space
  func center() -> R2Point {
    return R2Point(x: x.center(), y: y.center())
  }

  // Size returns the width and height of this rectangle in (x,y)-space. Empty
  // rectangles have a negative width and height.
  func size() -> R2Point {
    return R2Point(x: x.length(), y: y.length())
  }

  // MARK: tests 
  
  // ContainsPoint reports whether the rectangle contains the given point.
  // Rectangles are closed regions, i.e. they contain their boundary.
  func contains(_ point: R2Point) -> Bool {
    return x.contains(point.x) && y.contains(point.y)
  }

  // InteriorContainsPoint returns true iff the given point is contained in the interior
  // of the region (i.e. the region excluding its boundary).
  func interiorContains(_ point: R2Point) -> Bool {
    return x.interiorContains(point.x) && y.interiorContains(point.y)
  }

  // Contains reports whether the rectangle contains the given rectangle.
  func contains(_ rect: R2Rect) -> Bool {
    return x.contains(rect.x) && y.contains(rect.y)
  }

  // InteriorContains reports whether the interior of this rectangle contains all of the
  // points of the given other rectangle (including its boundary).
  func interiorContains(_ rect: R2Rect) -> Bool {
    return x.interiorContains(rect.x) && y.interiorContains(rect.y)
  }

  // Intersects reports whether this rectangle and the other rectangle have any points in common.
  func intersects(_ rect: R2Rect) -> Bool {
    return x.intersects(rect.x) && y.intersects(rect.y)
  }

  // InteriorIntersects reports whether the interior of this rectangle intersects
  // any point (including the boundary) of the given other rectangle.
  func interiorIntersects(_ rect: R2Rect) -> Bool {
    return x.interiorIntersects(rect.x) && y.interiorIntersects(rect.y)
  }

  //MARK: arithmetic
  
  // AddPoint expands the rectangle to include the given point. The rectangle is
  // expanded by the minimum amount possible.
  func add(_ point: R2Point) -> R2Rect {
    return R2Rect(x: x.add(point.x), y: y.add(point.y))
  }

  // AddRect expands the rectangle to include the given rectangle. This is the
  // same as replacing the rectangle by the union of the two rectangles, but
  // is more efficient.
  func add(_ rect: R2Rect) -> R2Rect {
    return R2Rect(x: x.union(rect.x), y: y.union(rect.y))
  }

  // ClampPoint returns the closest point in the rectangle to the given point.
  // The rectangle must be non-empty.
  func clamp(_ point: R2Point) -> R2Point {
    return R2Point(x: x.clamp(point.x), y: y.clamp(point.y))
  }

  // Expanded returns a rectangle that has been expanded in the x-direction
  // by margin.x, and in y-direction by margin.y. If either margin is empty,
  // then shrink the interval on the corresponding sides instead. The resulting
  // rectangle may be empty. Any expansion of an empty rectangle remains empty.
  func expanded(_ margin: R2Point) -> R2Rect {
    let xx = x.expanded(margin.x)
    let yy = y.expanded(margin.y)
    if xx.isEmpty() || yy.isEmpty() {
      return R2Rect.empty
    }
    return R2Rect(x: xx, y: yy)
  }

  // ExpandedByMargin returns a R2Rect that has been expanded by the amount on all sides.
  func expanded(_ margin: Double) -> R2Rect {
    return expanded(R2Point(x: margin, y: margin))
  }

  // Union returns the smallest rectangle containing the union of this rectangle and
  // the given rectangle.
  func union(_ rect: R2Rect) -> R2Rect {
    return R2Rect(x: x.union(rect.x), y: y.union(rect.y))
  }

  // Intersection returns the smallest rectangle containing the intersection of this
  // rectangle and the given rectangle.
  func intersection(_ rect: R2Rect) -> R2Rect {
    let xx = x.intersection(rect.x)
    let yy = y.intersection(rect.y)
    if xx.isEmpty() || yy.isEmpty() {
      return R2Rect.empty
    }
    
    return R2Rect(x: xx, y: yy)
  }

}
