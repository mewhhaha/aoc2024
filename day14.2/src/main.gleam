import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/set
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

  let iterations = iterate_robots(0, robots, bounds)

  io.println(iterations |> int.to_string)
}

fn iterate_robots(
  iteration: Int,
  robots: List(#(#(Int, Int), #(Int, Int))),
  bounds: #(Int, Int),
) {
  let new_robots = robots |> list.map(fn(r) { move_robot(r, bounds) })

  case no_stacking_robots(new_robots) {
    True -> {
      print_grid(new_robots, bounds)
      iteration + 1
    }
    False -> iterate_robots(iteration + 1, new_robots, bounds)
  }
}

fn no_stacking_robots(robots: List(#(#(Int, Int), #(Int, Int)))) {
  let unique_positions =
    robots
    |> list.map(fn(r) { r.0 })
    |> set.from_list
    |> set.size

  let number_of_robots = robots |> list.length

  unique_positions == number_of_robots
}

fn print_grid(robots: List(#(#(Int, Int), #(Int, Int))), bounds: #(Int, Int)) {
  let #(width, height) = bounds

  let grid = {
    use y <-
      fn(f) { list.range(0, height - 1) |> list.map(f) |> string.join("\n") }
    use x <-
      fn(f) { list.range(0, width - 1) |> list.map(f) |> string.join("") }

    case robots |> list.count(fn(r) { r.0.0 == x && r.0.1 == y }) {
      0 -> "."
      n -> n |> int.to_string
    }
  }

  io.println(grid)
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
