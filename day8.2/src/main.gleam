import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/option
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

    let anti_t1 =
      iterate_until(t1, fn(v) {
        let next = add(v, distance)
        case grid |> dict.has_key(next) {
          True -> option.Some(next)
          False -> option.None
        }
      })
    let anti_t2 =
      iterate_until(t2, fn(v) {
        let next = sub(v, distance)
        case grid |> dict.has_key(next) {
          True -> option.Some(next)
          False -> option.None
        }
      })

    anti_t1 |> list.append(anti_t2)
  }

  let unique_antinodes = all_antinodes |> list.unique |> list.length

  io.println(unique_antinodes |> int.to_string)
}

fn iterate_until(value, f) {
  do_iterate_until([], option.Some(value), f)
}

fn do_iterate_until(acc, value, f) {
  case value {
    option.None -> acc |> list.reverse
    option.Some(v) -> do_iterate_until([value, ..acc], f(v), f)
  }
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
