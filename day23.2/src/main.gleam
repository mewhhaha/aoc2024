import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string

pub fn main() {
  let t = lines()

  let connections =
    t
    |> list.flat_map(fn(line) {
      let assert [a, b] = line |> string.split("-")
      [#(a, b), #(b, a)]
    })
    |> list.group(fn(v) { v.0 })
    |> dict.map_values(fn(_, v) {
      v |> list.map(fn(v) { v.1 }) |> set.from_list
    })

  let valid_combinations = {
    use c0 <- fn(f) { connections |> dict.keys |> list.flat_map(f) }

    let assert Ok(adjacent) = connections |> dict.get(c0)

    let combinations = adjacent |> set.to_list |> list.combinations(2)

    use cs <- fn(f) { combinations |> list.filter_map(f) }

    let all = [c0, ..cs] |> set.from_list
    let permutations =
      all
      |> set.to_list
      |> list.map(fn(v) { #(v, all |> set.delete(v)) })

    case
      permutations
      |> list.all(fn(v) {
        let #(head, tail) = v

        let assert Ok(adj_head) = connections |> dict.get(head)
        let intersection = tail |> set.intersection(adj_head)
        intersection |> set.size == 2
      })
    {
      True -> Ok([c0, ..cs] |> list.sort(string.compare))
      False -> Error(Nil)
    }
  }

  let unique_valid_combinations =
    valid_combinations |> set.from_list |> set.to_list

  let combinations_with_t =
    unique_valid_combinations
    |> list.count(starts_with_t)

  let result = combinations_with_t
  io.println(result |> int.to_string)
}

fn starts_with_t(v: List(String)) -> Bool {
  v |> list.any(fn(v) { v |> string.starts_with("t") })
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
