import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub fn main() {
  let assert [towels_raw, _, ..patterns] = lines()

  let towels = towels_raw |> string.split(", ")
  let memo = towels |> list.map(fn(v) { #(v, True) }) |> dict.from_list
  let possible_patterns =
    patterns
    |> list.fold(#(memo, []), fn(acc, v) {
      case is_pattern_possible(acc.0, v, towels) {
        #(True, memo) -> #(memo, [v, ..acc.1])
        #(False, memo) -> #(memo, acc.1)
      }
    })
  let result = possible_patterns.1 |> list.length

  io.println(result |> int.to_string)
}

fn is_pattern_possible(
  memo: dict.Dict(String, Bool),
  pattern: String,
  towels: List(String),
) {
  case memo |> dict.get(pattern), pattern {
    Ok(v), _ -> #(v, memo)
    _, "" -> {
      #(True, memo |> dict.insert(pattern, True))
    }
    Error(_), _ -> {
      let valid_starts =
        towels |> list.filter(fn(v) { pattern |> string.starts_with(v) })

      case valid_starts {
        [] -> {
          #(False, memo |> dict.insert(pattern, False))
        }
        _ -> {
          case
            valid_starts
            |> list.fold(#(False, memo), fn(acc, v) {
              let shaved_pattern =
                pattern |> string.drop_start(v |> string.length)
              let #(success, memo) =
                is_pattern_possible(acc.1, shaved_pattern, towels)
              #(success || acc.0, memo)
            })
          {
            #(True, memo) -> #(True, memo |> dict.insert(pattern, True))
            #(False, memo) -> #(False, memo |> dict.insert(pattern, False))
          }
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
