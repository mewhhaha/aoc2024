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

pub fn main() {
  let t = lines()

  let assert Ok(map) =
    t
    |> list.index_map(fn(row, y) {
      row
      |> string.split("")
      |> list.index_map(fn(v, x) { #(#(x, y), v) })
      |> dict.from_list
    })
    |> list.reduce(dict.merge)

  let assert Ok(#(start, _)) =
    map
    |> dict.filter(fn(_, v) { v == "^" })
    |> dict.to_list
    |> list.first

  let walked_tiles = walk_guard(map, start)
  let result = walked_tiles |> set.size

  io.println(result |> int.to_string)
}

fn walk_guard(map: dict.Dict(#(Int, Int), String), position: #(Int, Int)) {
  do_walk_guard(set.from_list([position]), map, Up, position)
}

fn do_walk_guard(
  acc: set.Set(#(Int, Int)),
  map: dict.Dict(#(Int, Int), String),
  direction: Direction,
  position: #(Int, Int),
) {
  let next = move(position, direction)
  case map |> dict.get(next) {
    Ok("#") -> {
      do_walk_guard(acc, map, rotate_right(direction), position)
    }
    Ok(_) -> {
      do_walk_guard(acc |> set.insert(next), map, direction, next)
    }
    Error(_) -> {
      acc
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
