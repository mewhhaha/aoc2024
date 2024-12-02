import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/string

fn is_ascending(ns: List(Int)) -> Bool {
  ns == list.sort(ns, int.compare)
}

fn is_descending(ns: List(Int)) -> Bool {
  ns == list.sort(ns, int.compare) |> list.reverse
}

pub fn main() {
  let t = lines()

  let parse_line = fn(line: String) -> List(Int) {
    string.split(line, " ")
    |> list.map(fn(v) {
      let assert Ok(i) = v |> string.trim |> int.parse
      i
    })
  }

  let rows = t |> list.map(parse_line)

  let safe_rows =
    rows
    |> list.filter(fn(ns) {
      let ascending = is_ascending(ns)
      let descending = is_descending(ns)
      let sorted = ascending || descending

      sorted && difference(ns, 1, 3)
    })

  safe_rows
  |> list.map(fn(ns) {
    ns |> list.map(int.to_string) |> string.join(" ") |> io.println
  })

  io.println(int.to_string(list.length(safe_rows)))
}

fn difference(ns: List(Int), min: Int, max: Int) -> Bool {
  case ns {
    [a, b] -> {
      let diff = int.absolute_value(a - b)
      diff >= min && diff <= max
    }
    [a, b, ..rest] -> {
      let diff = int.absolute_value(a - b)
      case diff >= min && diff <= max {
        True -> difference([b, ..rest], min, max)
        False -> False
      }
    }
    _ -> True
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
      do_lines([v, ..acc])
    }
  }
}
