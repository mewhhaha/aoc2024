import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub fn main() {
  let assert [towels_raw, _, ..patterns] = lines()

  let towels = towels_raw |> string.split(", ")
  let possible_patterns =
    patterns
    |> list.fold(#(dict.new(), 0), fn(acc, v) {
      let #(n, memo) = is_pattern_possible(acc.0, v, towels)
      #(memo, n + acc.1)
    })
  let result = possible_patterns.1
  io.println(result |> int.to_string)
}

fn is_pattern_possible(
  memo: dict.Dict(String, Int),
  pattern: String,
  towels: List(String),
) {
  case memo |> dict.get(pattern), pattern {
    Ok(v), _ -> #(v, memo)
    _, "" -> {
      #(1, memo)
    }
    Error(_), _ -> {
      let valid_starts =
        towels |> list.filter(fn(v) { pattern |> string.starts_with(v) })

      case valid_starts {
        [] -> {
          #(0, memo |> dict.insert(pattern, 0))
        }
        _ -> {
          let #(n, memo) =
            valid_starts
            |> list.fold(#(0, memo), fn(acc, v) {
              let shaved_pattern =
                pattern |> string.drop_start(v |> string.length)
              let #(success, memo) =
                is_pattern_possible(acc.1, shaved_pattern, towels)
              #(success + acc.0, memo)
            })

          #(n, memo |> dict.insert(pattern, n))
        }
      }
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
