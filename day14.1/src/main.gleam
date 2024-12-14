import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/string

pub fn main() {
  let assert [bounds_raw, ..t] = lines()

  let assert [width_raw, height_raw] = string.split(bounds_raw, ",")

  let assert Ok(width) = int.parse(width_raw)
  let assert Ok(height) = int.parse(height_raw)

  let bounds = #(width, height)

  let options = regexp.Options(case_insensitive: False, multi_line: False)
  let assert Ok(re) =
    regexp.compile("p=([0-9]+),([0-9]+) v=(-?[0-9]+),(-?[0-9]+)", options)

  let robots =
    t
    |> list.map(fn(line) {
      let assert [
        regexp.Match(_, [Some(x_raw), Some(y_raw), Some(vx_raw), Some(vy_raw)]),
      ] = regexp.scan(re, line)

      let assert Ok(x) = int.parse(x_raw)
      let assert Ok(y) = int.parse(y_raw)
      let assert Ok(vx) = int.parse(vx_raw)
      let assert Ok(vy) = int.parse(vy_raw)

      #(#(x, y), #(vx, vy))
    })

  let moved_grid =
    list.range(0, 99)
    |> list.fold(robots, fn(acc, _) {
      acc |> list.map(fn(r) { move_robot(r, bounds) })
    })

  // print_grid(moved_grid, bounds)

  let result = count_in_quadrants(moved_grid, bounds)

  io.println(result |> int.to_string)
}

fn count_in_quadrants(
  robots: List(#(#(Int, Int), #(Int, Int))),
  bounds: #(Int, Int),
) -> Int {
  let #(grid_width, grid_height) = bounds
  let #(width, height) = #(grid_width / 2, grid_height / 2)

  let top_left = #(0, 0)
  let top_right = #(width + 1, 0)
  let bottom_left = #(0, height + 1)
  let bottom_right = #(width + 1, height + 1)

  let quadrants =
    [top_left, top_right, bottom_left, bottom_right]
    |> list.map(fn(v) { count_in_quadrant(robots, v, #(width - 1, height - 1)) })

  quadrants |> list.fold(1, int.multiply)
}

// fn print_grid(robots: List(#(#(Int, Int), #(Int, Int))), bounds: #(Int, Int)) {
//   let #(width, height) = bounds

//   let grid = {
//     use y <-
//       fn(f) { list.range(0, height - 1) |> list.map(f) |> string.join("\n") }
//     use x <-
//       fn(f) { list.range(0, width - 1) |> list.map(f) |> string.join("") }

//     case robots |> list.count(fn(r) { r.0.0 == x && r.0.1 == y }) {
//       0 -> "."
//       n -> n |> int.to_string
//     }
//   }

//   io.println(grid)
// }

fn count_in_quadrant(
  robots: List(#(#(Int, Int), #(Int, Int))),
  quadrant: #(Int, Int),
  quadrant_size: #(Int, Int),
) -> Int {
  robots
  |> list.count(fn(r) {
    let #(#(x, y), _) = r

    let #(left, top) = quadrant

    let right = left + quadrant_size.0
    let bottom = top + quadrant_size.1

    x >= left && x <= right && y >= top && y <= bottom
  })
}

fn move_robot(robot: #(#(Int, Int), #(Int, Int)), bounds: #(Int, Int)) {
  let #(#(x, y), #(vx, vy)) = robot

  let assert Ok(new_x) = int.modulo(x + vx, bounds.0)
  let assert Ok(new_y) = int.modulo(y + vy, bounds.1)

  #(#(new_x, new_y), #(vx, vy))
}

fn lines() -> List(String) {
  do_lines([])
}

fn do_lines(acc: List(String)) -> List(String) {
  case erlang.get_line("") {
    Error(_) -> {
      acc |> list.reverse
    }
    Ok(v) -> {
      do_lines([string.trim_end(v), ..acc])
    }
  }
}
