import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/string

type Behavior {
  Behavior(a: #(Int, Int), b: #(Int, Int), p: #(Int, Int))
}

pub fn main() {
  let t = lines()

  let options = regexp.Options(case_insensitive: False, multi_line: False)

  let assert Ok(re_a) =
    regexp.compile("Button A: X\\+([0-9]+), Y\\+([0-9]+)", options)
  let assert Ok(re_b) =
    regexp.compile("Button B: X\\+([0-9]+), Y\\+([0-9]+)", options)
  let assert Ok(re_prize) =
    regexp.compile("Prize: X=([0-9]+), Y=([0-9]+)", options)

  let behaviours =
    t
    |> split_on("")
    |> list.map(fn(v) {
      let assert [a, b, p] = v
      let assert [regexp.Match(_, [option.Some(a_x), option.Some(a_y)])] =
        regexp.scan(re_a, a)
      let assert [regexp.Match(_, [option.Some(b_x), option.Some(b_y)])] =
        regexp.scan(re_b, b)
      let assert [regexp.Match(_, [option.Some(p_x), option.Some(p_y)])] =
        regexp.scan(re_prize, p)

      let assert Ok(a_x) = int.parse(a_x)
      let assert Ok(a_y) = int.parse(a_y)
      let assert Ok(b_x) = int.parse(b_x)
      let assert Ok(b_y) = int.parse(b_y)
      let assert Ok(p_x) = int.parse(p_x)
      let assert Ok(p_y) = int.parse(p_y)

      Behavior(#(a_x, a_y), #(b_x, b_y), #(
        p_x + 10_000_000_000_000,
        p_y + 10_000_000_000_000,
      ))
    })

  let button_presses = behaviours |> list.map(calc_button_presses)

  let tokens =
    button_presses
    |> list.map(fn(v) {
      case v {
        Ok(#(press_a, press_b)) -> press_a * 3 + press_b
        Error(_) -> 0
      }
    })

  let result = tokens |> list.fold(0, int.add)

  io.println(result |> int.to_string)
}

fn calc_button_presses(behavior: Behavior) {
  let Behavior(a, b, c) = behavior

  do_calc_button_presses(a, b, c)
}

fn do_calc_button_presses(a: #(Int, Int), b: #(Int, Int), prize: #(Int, Int)) {
  // Just had to solve for a and b in these equations:
  // a.x * press_a + b.x * press_b = prize.x
  // a.y * press_a + b.y * press_b = prize.y

  let c1 = a.0
  let c2 = b.0
  let c3 = prize.0

  let c4 = a.1
  let c5 = b.1
  let c6 = prize.1

  let press_a = { c3 * c5 - c2 * c6 } / { c1 * c5 - c2 * c4 }

  let press_b = { c3 * c4 - c1 * c6 } / { c2 * c4 - c1 * c5 }

  case tuple_add(scale(a, press_a), scale(b, press_b)) == prize {
    True -> Ok(#(press_a, press_b))
    False -> Error(Nil)
  }
}

fn scale(a: #(Int, Int), m: Int) {
  #(a.0 * m, a.1 * m)
}

fn tuple_add(a: #(Int, Int), b: #(Int, Int)) {
  #(a.0 + b.0, a.1 + b.1)
}

fn split_on(l: List(value), value) {
  do_split_on([], l, value)
}

fn do_split_on(acc: List(value), l: List(value), value) {
  case l {
    [v, ..rest] if v == value -> {
      [acc |> list.reverse, ..do_split_on([], rest, value)]
    }
    [v, ..rest] -> {
      do_split_on([v, ..acc], rest, value)
    }
    [] -> {
      [acc |> list.reverse]
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
