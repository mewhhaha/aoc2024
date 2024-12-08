import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

pub fn main() {
  let t = lines()

  let assert Ok(grid) = to_grid(t |> list.map(chars))

  let grouped_nodes =
    grid
    |> dict.to_list()
    |> list.filter(fn(t) { t.1 != "." })
    |> list.group(fn(t) { t.1 })

  let all_antinodes = {
    use nodes <- fn(f) { grouped_nodes |> dict.values |> list.flat_map(f) }
    use list <- fn(f) { nodes |> list.combinations(2) |> list.flat_map(f) }
    let assert [t1, t2] = list |> list.map(fst)

    let distance = sub(t1, t2)

    let anti_t1 = add(t1, distance)
    let anti_t2 = sub(t2, distance)

    use coord <- fn(f) { [anti_t1, anti_t2] |> list.filter(f) }

    grid |> dict.get(coord) |> result.is_ok
  }

  let unique_antinodes = all_antinodes |> list.unique |> list.length

  io.println(unique_antinodes |> int.to_string)
}

fn fst(t: #(a, b)) {
  t.0
}

fn sub(a: #(Int, Int), b: #(Int, Int)) {
  #(a.0 - b.0, a.1 - b.1)
}

fn add(a: #(Int, Int), b: #(Int, Int)) {
  #(a.0 + b.0, a.1 + b.1)
}

fn chars(line: String) -> List(String) {
  line |> string.split("")
}

fn to_grid(lines: List(List(value))) {
  use row, y <- fn(f) { lines |> list.index_map(f) |> list.reduce(dict.merge) }

  use v, x <- fn(f) { row |> list.index_map(f) |> dict.from_list }

  #(#(x, y), v)
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
