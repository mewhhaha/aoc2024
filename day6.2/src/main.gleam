import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string

type Direction {
  Up
  Down
  Left
  Right
}

type Result {
  Loop
  Exit(set.Set(#(Int, Int)))
}

pub fn main() {
  let t = lines()

  let assert Ok(map) = t |> list.map(fn(v) { v |> string.split("") }) |> to_grid

  let assert Ok(#(start, _)) = find_first_value(map, "^")

  let assert Exit(walked_tiles) = walk_guard(map, start)

  let looped_paths = {
    use tile <- fn(f) { walked_tiles |> set.filter(f) }

    let with_tile = map |> dict.insert(tile, "#")
    case walk_guard(with_tile, start) {
      Loop -> {
        True
      }
      Exit(_) -> {
        False
      }
    }
  }

  let result = looped_paths |> set.size

  io.println(result |> int.to_string)
}

fn find_first_value(map: dict.Dict(key, value), value: value) {
  map |> dict.filter(fn(_, v) { v == value }) |> dict.to_list |> list.first
}

fn to_grid(lines: List(List(value))) {
  use row, y <- fn(f) { lines |> list.index_map(f) |> list.reduce(dict.merge) }

  use v, x <- fn(f) { row |> list.index_map(f) |> dict.from_list }

  #(#(x, y), v)
}

fn walk_guard(map: dict.Dict(#(Int, Int), String), position: #(Int, Int)) {
  do_walk_guard(set.from_list([#(position, Up)]), map, Up, position)
}

fn do_walk_guard(
  acc: set.Set(#(#(Int, Int), Direction)),
  map: dict.Dict(#(Int, Int), String),
  direction: Direction,
  position: #(Int, Int),
) {
  let next = move(position, direction)
  case acc |> set.contains(#(next, direction)), map |> dict.get(next) {
    True, _ -> {
      Loop
    }
    False, Ok("#") -> {
      do_walk_guard(acc, map, rotate_right(direction), position)
    }
    False, Ok(_) -> {
      do_walk_guard(acc |> set.insert(#(next, direction)), map, direction, next)
    }
    _, Error(_) -> {
      acc |> set.map(fn(p) { p.0 }) |> Exit
    }
  }
}

fn move(position: #(Int, Int), direction: Direction) {
  case direction {
    Up -> #(position.0, position.1 - 1)
    Down -> #(position.0, position.1 + 1)
    Left -> #(position.0 - 1, position.1)
    Right -> #(position.0 + 1, position.1)
  }
}

fn rotate_right(direction: Direction) {
  case direction {
    Up -> Right
    Right -> Down
    Down -> Left
    Left -> Up
  }
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
