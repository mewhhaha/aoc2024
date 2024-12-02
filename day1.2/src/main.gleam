import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp

pub fn main() {
  let t = lines()

  let options = regexp.Options(case_insensitive: False, multi_line: False)
  let assert Ok(re) = regexp.compile("([0-9]+)\\s+([0-9]+)", options)

  let parse_line = fn(line: String) -> List(Int) {
    let assert [match] = re |> regexp.scan(line)
    let assert [option.Some(a), option.Some(b)] = match.submatches
    let assert Ok(ia) = int.parse(a)
    let assert Ok(ib) = int.parse(b)
    [ia, ib]
  }

  let assert [col1, col2] =
    t
    |> list.map(parse_line)
    |> list.transpose

  let grouped = col2 |> list.group(fn(v) { v })

  let assert Ok(sum) =
    col1
    |> list.map(fn(v) {
      let ns = case grouped |> dict.get(v) {
        Ok(ns) -> ns
        Error(_) -> []
      }
      v * list.length(ns)
    })
    |> list.reduce(int.add)

  io.println(int.to_string(sum))
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
      do_lines([v, ..acc])
    }
  }
}
