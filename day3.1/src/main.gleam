import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/string

type Mul =
  #(Int, Int)

pub fn main() {
  let t = lines()

  let single_string = t |> list.map(string.trim) |> string.join("")

  let muls = parse_muls(single_string)

  let assert Ok(result) =
    muls
    |> list.map(fn(mul) { mul.0 * mul.1 })
    |> list.reduce(int.add)

  io.println(int.to_string(result))
  // io.println(int.to_string(list.length(safe_rows)))
}

fn parse_muls(s: String) -> List(Mul) {
  let options = regexp.Options(case_insensitive: False, multi_line: False)
  let assert Ok(re) = regexp.compile("mul\\(([0-9]+),([0-9]+)\\)", options)

  let matches = regexp.scan(re, s)

  matches
  |> list.map(fn(m) {
    let assert [Some(a), Some(b)] = m.submatches
    let assert Ok(ia) = int.parse(a)
    let assert Ok(ib) = int.parse(b)
    #(ia, ib)
  })
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
