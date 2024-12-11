import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub fn main() {
  let assert [t] = lines()
  let initial_stones =
    t
    |> string.split(" ")
    |> list.map(fn(v) {
      let assert Ok(o) = int.parse(v)
      o
    })

  let result = initial_stones |> iterate(blink, 25) |> list.length

  io.println(result |> int.to_string)
}

fn iterate(value: value, f: fn(value) -> value, n: Int) {
  let result = list.range(1, n) |> list.fold(value, fn(acc, _) { f(acc) })
  result
}

fn blink(stones: List(Int)) {
  do_blink([], stones)
}

fn do_blink(acc: List(Int), stones: List(Int)) {
  case stones {
    [] -> acc |> list.reverse
    [0, ..tail] -> {
      do_blink([1, ..acc], tail)
    }
    [head, ..tail] -> {
      let digits = head |> int.to_string
      case string.length(digits) % 2 == 0 {
        True -> {
          let length = string.length(digits)
          let mid_point = length / 2
          let assert Ok(left_stone) =
            digits
            |> string.slice(0, mid_point)
            |> int.parse

          let assert Ok(right_stone) =
            digits
            |> string.slice(mid_point, length)
            |> unpad_start(1, "0")
            |> int.parse

          do_blink([right_stone, left_stone, ..acc], tail)
        }
        False -> {
          do_blink([head * 2024, ..acc], tail)
        }
      }
    }
  }
}

fn unpad_start(text: String, n: Int, c: String) {
  let text_to_trim = text |> string.slice(0, string.length(text) - n)
  let text_remain =
    text |> string.slice(string.length(text) - n, string.length(text))

  let text_trimmed =
    text_to_trim
    |> string.to_graphemes
    |> list.drop_while(fn(v) { v == c })
    |> string.join("")

  text_trimmed <> text_remain
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
