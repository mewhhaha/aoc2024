import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

type Instruction {
  Up
  Down
  Left
  Right
}

type Spot {
  Empty
  Wall
  Robot
  Box
}

pub fn main() {
  let t = lines()

  let assert [map_raw, ..instructions_raw] = t |> split_on("")

  let assert Ok(map) =
    map_raw
    |> list.map(fn(l) { l |> string.to_graphemes |> list.map(parse_spot) })
    |> to_grid()

  let instructions =
    instructions_raw
    |> list.flatten
    |> list.flat_map(string.to_graphemes)
    |> list.map(parse_instruction)

  let assert Ok(start) =
    map
    |> dict.to_list()
    |> list.find(fn(t) { t.1 == Robot })

  let #(_, final_map) =
    instructions
    |> list.fold(#(start, map), fn(state, instruction) {
      let #(start, map) = state
      case execute_instruction(map, start, instruction) {
        Ok(#(new_start, new_map)) -> {
          #(new_start, new_map)
        }
        Error(_) -> #(start, map)
      }
    })

  print_map(final_map)

  let scores =
    final_map
    |> dict.filter(fn(_, v) { v == Box })
    |> dict.keys
    |> list.map(fn(position) { position.1 * 100 + position.0 })

  let result = scores |> list.fold(0, int.add)
  io.println(result |> int.to_string)
}

fn print_map(map: dict.Dict(#(Int, Int), Spot)) {
  let result =
    map
    |> dict.to_list()
    |> list.sort(fn(a, b) { int.compare(a.0.1, b.0.1) })
    |> list.chunk(fn(a) { a.0.1 })
    |> list.map(fn(row) {
      row
      |> list.sort(fn(a, b) { int.compare(a.0.0, b.0.0) })
      |> list.map(fn(cell) {
        case cell.1 {
          Empty -> "."
          Wall -> "#"
          Robot -> "@"
          Box -> "O"
        }
      })
      |> string.join("")
    })

  result |> list.each(io.println)
}

fn execute_instruction(
  map: dict.Dict(#(Int, Int), Spot),
  at: #(#(Int, Int), Spot),
  instruction: Instruction,
) {
  let #(position, spot) = at

  let movement = case instruction {
    Up -> #(position.0, position.1 - 1)
    Down -> #(position.0, position.1 + 1)
    Left -> #(position.0 - 1, position.1)
    Right -> #(position.0 + 1, position.1)
  }

  let assert Ok(v) = map |> dict.get(movement)

  use #(_, current_map) <- result.try(case v {
    Empty -> Ok(#(#(movement, Empty), map))
    Wall -> Error(Nil)
    Robot -> Error(Nil)
    Box -> execute_instruction(map, #(movement, Box), instruction)
  })

  let updated_map =
    current_map
    |> dict.insert(movement, spot)
    |> dict.insert(position, Empty)

  Ok(#(#(movement, spot), updated_map))
}

fn parse_spot(v: String) {
  case v {
    "." -> Empty
    "#" -> Wall
    "@" -> Robot
    "O" -> Box
    _ -> panic
  }
}

fn parse_instruction(v: String) {
  case v {
    "^" -> Up
    "v" -> Down
    "<" -> Left
    ">" -> Right
    _ -> panic
  }
}

fn to_grid(lines: List(List(value))) {
  use row, y <- fn(f) { lines |> list.index_map(f) |> list.reduce(dict.merge) }

  use v, x <- fn(f) { row |> list.index_map(f) |> dict.from_list }

  #(#(x, y), v)
}

fn split_on(l: List(value), value) {
  do_split_on([], l, value)
}

fn do_split_on(acc: List(value), l: List(value), value) {
  case l {
    [v, ..rest] if v == value -> {
      [acc |> list.reverse, ..do_split_on([], rest, value)]
    }
    [v, ..rest] -> {
      do_split_on([v, ..acc], rest, value)
    }
    [] -> {
      [acc |> list.reverse]
    }
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
