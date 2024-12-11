import gleam/dict
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

  let after_blinking = iterate_blink(initial_stones, 75)

  let result =
    after_blinking
    |> dict.values
    |> list.fold(0, int.add)
  io.println(result |> int.to_string)
}

fn iterate_blink(stones: List(Int), n: Int) {
  case n {
    0 -> {
      stones |> list.map(fn(v) { #(v, 1) }) |> dict.from_list
    }
    _ -> {
      let grouped_stones =
        stones |> group_by_number |> list.map(fn(v) { #(v.0, v.1, blink(v.0)) })

      let next_stones = grouped_stones |> list.flat_map(fn(v) { v.2 })

      let next_scores = iterate_blink(next_stones, n - 1)

      let scores =
        grouped_stones
        |> list.map(fn(v) {
          let score =
            v.2
            |> list.map(fn(w) {
              let assert Ok(score) = next_scores |> dict.get(w)
              score
            })
            |> list.fold(0, int.add)

          #(v.0, score)
        })
        |> dict.from_list

      scores
    }
  }
}

fn group_by_number(stones: List(Int)) {
  stones
  |> list.group(fn(stone) { stone })
  |> dict.map_values(fn(k, v) { #(k, list.length(v)) })
  |> dict.values
}

fn blink(stone: Int) {
  do_blink(stone)
}

fn do_blink(stone: Int) {
  case stone {
    0 -> {
      [1]
    }
    head -> {
      let digits = head |> int.to_string
      case string.length(digits) % 2 == 0 {
        True -> {
          split_digits(head)
        }
        False -> {
          [head * 2024]
        }
      }
    }
  }
}

fn split_digits(n: Int) {
  let digits = n |> int.to_string
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

  [left_stone, right_stone]
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
