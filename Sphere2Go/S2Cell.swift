//
//  S2Cell.swift
//  Sphere2
//

import Foundation


// package s2
// import math, r1, r2, s1

// Cell is an S2 region object that represents a cell. Unlike CellIDs,
// it supports efficient containment and intersection tests. However, it is
// also a more expensive representation.
struct Cell: S2Region {
  
  // TODO(akashagrawal): move these package private variables to a more appropriate location.
  static let dblEpsilon = nextafter(1.0, 2.0) - 1.0
  static let poleMinLat = asin(sqrt(1.0 / 3.0)) - 0.5 * dblEpsilon

  //
  let face: UInt8
  let level: UInt8
//  let orientation: UInt8
  let id: CellId
  let uv: R2Rect

  // MARK: inits / factory
  
//  init(face: UInt8, level: UInt8, orientation: UInt8, id: CellId, uv: R2Rect) {
//  face: UInt8
//  let level: UInt8
//  let orientation: UInt8
//  let id: CellId
//  let uv: R2Rect
//  }
  
  // CellFromCellID constructs a Cell corresponding to the given CellID.
  init(id: CellId) {
    self.id = id
    level = UInt8(id.level())
    let (f, i, j, _) = id.faceIJOrientation()
    face = UInt8(f)
//    orientation = UInt8(o)
    uv = CellId.ijLevelToBoundUV(i: i, j: j, level: Int(level))
  }

  // CellFromPoint constructs a cell for the given Point.
  init(point: S2Point) {
    let cellId = CellId(point: point)
    self.init(id: cellId)
  }

  // CellFromLatLng constructs a cell for the given LatLng.
  init (latLng: LatLng) {
    let cellId = CellId(latLng: latLng)
    self.init(id: cellId)
  }

  // MARK: tests
  
  // IsLeaf returns whether this Cell is a leaf or not.
  func isLeaf() -> Bool {
    return level == UInt8(CellId.maxLevel)
  }

  // MARK: computed members
  
  // SizeIJ returns the CellID value for the cells level.
  func sizeIJ() -> Int {
    return CellId.sizeIJ(Int(level))
  }

  // Vertex returns the k-th vertex of the cell (k = [0,3]) in CCW order
  // (lower left, lower right, upper right, upper left in the UV plane).
  func vertex(_ k: Int) -> S2Point {
    let face = Int(self.face)
    let u = uv.vertices()[k].x
    let v = uv.vertices()[k].y
    return S2Point(raw: S2Cube(face: face, u: u, v: v).vector())
  }

  // Edge returns the inward-facing normal of the great circle passing through
  // the CCW ordered edge from vertex k to vertex k+1 (mod 4).
  func edge(_ k: Int) -> S2Point {
    switch k {
    case 0:
      return S2Cube.vNorm(face: Int(face), v: uv.y.lo, invert: false) // Bottom
    case 1:
      return S2Cube.uNorm(face: Int(face), u: uv.x.hi, invert: false) // Right
    case 2:
      return S2Cube.vNorm(face: Int(face), v: uv.y.hi, invert: true) // Top
    default:
      return S2Cube.uNorm(face: Int(face), u: uv.x.lo, invert: true) // Left
    }
  }

  // ExactArea returns the area of this cell as accurately as possible.
  func exactArea() -> Double {
    let (v0, v1, v2, v3) = (vertex(0), vertex(1), vertex(2), vertex(3))
    return S2Point.pointArea(v0, v1, v2) + S2Point.pointArea(v0, v2, v3)
  }

  // ApproxArea returns the approximate area of this cell. This method is accurate
  // to within 3% percent for all cell sizes and accurate to within 0.1% for cells
  // at level 5 or higher (i.e. squares 350km to a side or smaller on the Earth's
  // surface). It is moderately cheap to compute.
  func approxArea() -> Double {
    // All cells at the first two levels have the same area.
    if level < 2 {
      return averageArea()
    }
    
    // First, compute the approximate area of the cell when projected
    // perpendicular to its normal. The cross product of its diagonals gives
    // the normal, and the length of the normal is twice the projected area.
    let flatArea = 0.5 * (vertex(2).v.sub(vertex(0).v).cross(vertex(3).v.sub(vertex(1).v)).norm())
    
    // Now, compensate for the curvature of the cell surface by pretending
    // that the cell is shaped like a spherical cap. The ratio of the
    // area of a spherical cap to the area of its projected disc turns out
    // to be 2 / (1 + sqrt(1 - r*r)) where r is the radius of the disc.
    // For example, when r=0 the ratio is 1, and when r=1 the ratio is 2.
    // Here we set Pi*r*r == flatArea to find the equivalent disc.
    return flatArea * 2 / (1.0 + sqrt(1 - min(1.0 / .pi * flatArea, 1)))
  }

  // AverageArea returns the average area of cells at the level of this cell.
  // This is accurate to within a factor of 1.7.
  func averageArea() -> Double {
    return Metric.avgArea.value(Int(level))
  }

  // MARK: derive lat/lng from uv
  
  // latitude returns the latitude of the cell vertex given by (i,j), where "i" and "j" are either 0 or 1.
  func latitude(i: Int, j: Int) -> Double {
    var u: Double
    var v: Double
    switch (i, j) {
    case (0, 0):
      u = uv.x.lo
      v = uv.y.lo
    case (0, 1):
      u = uv.x.lo
      v = uv.y.hi
    case (1, 0):
      u = uv.x.hi
      v = uv.y.lo
    case (1, 1):
      u = uv.x.hi
      v = uv.y.hi
    default:
      fatalError("i and/or j is out of bound")
    }
    let p = S2Point(raw: S2Cube(face: Int(face), u: u, v: v).vector())
    return p.latitude()
  }

  // longitude returns the longitude of the cell vertex given by (i,j), where "i" and "j" are either 0 or 1.
  func longitude(i: Int, j: Int) -> Double {
    var u: Double
    var v: Double
    switch (i, j) {
    case (0, 0):
      u = uv.x.lo
      v = uv.y.lo
    case (0, 1):
      u = uv.x.lo
      v = uv.y.hi
    case (1, 0):
      u = uv.x.hi
      v = uv.y.lo
    case (1, 1):
      u = uv.x.hi
      v = uv.y.hi
    default:
      fatalError("i and/or j is out of bound")
    }
    let p = S2Point(raw: S2Cube(face: Int(face), u: u, v: v).vector())
    return p.longitude()
  }

  // RectBound returns the bounding rectangle of this cell.
  func rectBound() -> S2Rect {
    if level > 0 {
      // Except for cells at level 0, the latitude and longitude extremes are
      // attained at the vertices.  Furthermore, the latitude range is
      // determined by one pair of diagonally opposite vertices and the
      // longitude range is determined by the other pair.
      //
      // We first determine which corner (i,j) of the cell has the largest
      // absolute latitude.  To maximize latitude, we want to find the point in
      // the cell that has the largest absolute z-coordinate and the smallest
      // absolute x- and y-coordinates.  To do this we look at each coordinate
      // (u and v), and determine whether we want to minimize or maximize that
      // coordinate based on the axis direction and the cell's (u,v) quadrant.
      let u = uv.x.lo + uv.x.hi
      let v = uv.y.lo + uv.y.hi
      var i = 0
      var j = 0
      if S2Cube.uAxis(face: Int(face)).z == 0 {
        if u < 0 {
          i = 1
        }
      } else if u > 0 {
        i = 1
      }
      if S2Cube.vAxis(face: Int(face)).z == 0 {
        if v < 0 {
          j = 1
        }
      } else if v > 0 {
        j = 1
      }
      let lat = R1Interval(point: latitude(i: i, j: j)).add(latitude(i: 1-i, j: 1-j))
      let lng = S1Interval.empty.add(longitude(i: i, j: 1-j)).add(longitude(i: 1-i, j: j))
      
      // We grow the bounds slightly to make sure that the bounding rectangle
      // contains LatLngFromPoint(P) for any point P inside the loop L defined by the
      // four *normalized* vertices.  Note that normalization of a vector can
      // change its direction by up to 0.5 * dblEpsilon radians, and it is not
      // enough just to add Normalize calls to the code above because the
      // latitude/longitude ranges are not necessarily determined by diagonally
      // opposite vertex pairs after normalization.
      //
      // We would like to bound the amount by which the latitude/longitude of a
      // contained point P can exceed the bounds computed above.  In the case of
      // longitude, the normalization error can change the direction of rounding
      // leading to a maximum difference in longitude of 2 * dblEpsilon.  In
      // the case of latitude, the normalization error can shift the latitude by
      // up to 0.5 * dblEpsilon and the other sources of error can cause the
      // two latitudes to differ by up to another 1.5 * dblEpsilon, which also
      // leads to a maximum difference of 2 * dblEpsilon.
      return S2Rect(lat: lat, lng: lng).expanded(LatLng(lat: 2 * Cell.dblEpsilon, lng: 2 * Cell.dblEpsilon)).polarClosure()
    }
    
    // The 4 cells around the equator extend to +/-45 degrees latitude at the
    // midpoints of their top and bottom edges.  The two cells covering the
    // poles extend down to +/-35.26 degrees at their vertices.  The maximum
    // error in this calculation is 0.5 * dblEpsilon.
    let bound: S2Rect
    switch face {
    case 0:
      bound = S2Rect(lat: R1Interval(lo: -.pi / 4, hi: .pi / 4), lng: S1Interval(lo: -.pi / 4, hi: .pi / 4))
    case 1:
      bound = S2Rect(lat: R1Interval(lo: -.pi / 4, hi: .pi / 4), lng: S1Interval(lo: .pi / 4, hi: 3 * .pi / 4))
    case 2:
      bound = S2Rect(lat: R1Interval(lo: Cell.poleMinLat, hi: .pi / 2), lng: S1Interval.full)
    case 3:
      bound = S2Rect(lat: R1Interval(lo: -.pi / 4, hi: .pi / 4), lng: S1Interval(lo: 3 * .pi / 4, hi: -3 * .pi / 4))
    case 4:
      bound = S2Rect(lat: R1Interval(lo: -.pi / 4, hi: .pi / 4), lng: S1Interval(lo: -3 * .pi / 4, hi: -.pi / 4))
    default:
      bound = S2Rect(lat: R1Interval(lo: -.pi / 2, hi: -Cell.poleMinLat), lng: S1Interval.full)
    }
    
    // Finally, we expand the bound to account for the error when a point P is
    // converted to an LatLng to test for containment. (The bound should be
    // large enough so that it contains the computed LatLng of any contained
    // point, not just the infinite-precision version.) We don't need to expand
    // longitude because longitude is calculated via a single call to math.Atan2,
    // which is guaranteed to be semi-monotonic.
    return bound.expanded(LatLng(lat: Cell.dblEpsilon, lng: 0.0))
  }

  // CapBound returns the bounding cap of this cell.
  func capBound() -> S2Cap {
    // We use the cell center in (u,v)-space as the cap axis.  This vector is very close
    // to GetCenter() and faster to compute.  Neither one of these vectors yields the
    // bounding cap with minimal surface area, but they are both pretty close.
    let p = S2Point(raw: S2Cube(face: Int(face), u: uv.center().x, v: uv.center().y).vector().normalize())
    var cap = S2Cap(point: p)
    for k in 0..<4 {
      cap = cap.add(vertex(k))
    }
    return cap
  }

  // MARK: contains / intersects
  
  // IntersectsCell reports whether the intersection of this cell and the other cell is not nil.
  func intersects(_ cell: Cell) -> Bool {
    return id.intersects(cell.id)
  }
  
  // ContainsCell reports whether this cell contains the other cell.
  func contains(_ cell: Cell) -> Bool {
    return id.contains(cell.id)
  }
  
  // ContainsPoint reports whether this cell contains the given point. Note that
  // unlike Loop/Polygon, a Cell is considered to be a closed set. This means
  // that a point on a Cell's edge or vertex belong to the Cell and the relevant
  // adjacent Cells too.
  //
  // If you want every point to be contained by exactly one Cell,
  // you will need to convert the Cell to a Loop.
  func contains(_ point: S2Point) -> Bool {
    guard let cube = S2Cube(point: point, face: Int(face)) else {
      return false
    }
    let uv2 = R2Point(x: cube.u, y: cube.v)
    
    // Expand the (u,v) bound to ensure that
    //
    //   CellFromPoint(p).ContainsPoint(p)
    //
    // is always true. To do this, we need to account for the error when
    // converting from (u,v) coordinates to (s,t) coordinates. In the
    // normal case the total error is at most dblEpsilon.
    return uv.expanded(Cell.dblEpsilon).contains(uv2)
  }

  // TODO(roberts, or $SOMEONE): Differences from C++, almost everything else still.
  // Implement the accessor methods on the internal fields.
}
