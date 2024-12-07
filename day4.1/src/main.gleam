import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub fn main() {
  let t = lines()

  let assert Ok(map) =
    t
    |> list.index_map(fn(line, y) {
      line
      |> string.split("")
      |> list.index_map(fn(char, x) { #(#(x, y), char) })
      |> dict.from_list
    })
    |> list.reduce(dict.merge)

  let starts = map |> dict.filter(fn(_, char) { char == "X" }) |> dict.keys

  let directions = [
    #(1, 1),
    #(-1, 1),
    #(1, -1),
    #(-1, -1),
    #(0, 1),
    #(1, 0),
    #(0, -1),
    #(-1, 0),
  ]

  let word = ["X", "M", "A", "S"]

  let coords = {
    use start <- fn(f) { starts |> list.flat_map(f) }
    use direction <- fn(f) { directions |> list.map(f) }
    use coord <- fn(f) { start |> iterate(list.length(word), f) }

    add(coord, direction)
  }

  let result = {
    use row <- fn(f) { coords |> list.filter(f) }
    use #(char, coord) <- fn(f) { list.zip(word, row) |> list.all(f) }

    map |> dict.get(coord) == Ok(char)
  }

  io.println(int.to_string(list.length(result)))
}

fn iterate(start: value, n: Int, f: fn(value) -> value) -> List(value) {
  do_iterate([], start, n, f)
}

fn do_iterate(
  acc: List(value),
  start: value,
  n: Int,
  f: fn(value) -> value,
) -> List(value) {
  case n {
    0 -> list.reverse(acc)
    _ -> do_iterate([start, ..acc], f(start), n - 1, f)
  }
}

fn add(a: #(Int, Int), b: #(Int, Int)) -> #(Int, Int) {
  #(a.0 + b.0, a.1 + b.1)
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
