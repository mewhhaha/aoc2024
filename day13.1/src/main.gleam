import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
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

      Behavior(#(a_x, a_y), #(b_x, b_y), #(p_x, p_y))
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

  do_calc_button_presses(100, a, b, c)
}

fn do_calc_button_presses(
  press_b: Int,
  a: #(Int, Int),
  b: #(Int, Int),
  prize: #(Int, Int),
) {
  let mul_b = tuple_multiply(press_b, b)
  let without_b = tuple_sub(prize, mul_b)

  case
    press_b < 0,
    {
      use x <- result.try(safe_divide(without_b.0, a.0))
      use y <- result.try(safe_divide(without_b.1, a.1))

      case x == y {
        True -> Ok(#(x, press_b))
        False -> do_calc_button_presses(press_b - 1, a, b, prize)
      }
    }
  {
    True, _ -> Error(Nil)
    _, Ok(v) -> Ok(v)
    _, Error(_) -> do_calc_button_presses(press_b - 1, a, b, prize)
  }
}

fn safe_divide(a: Int, b: Int) {
  let divisable = a % b == 0

  case divisable {
    True -> Ok(a / b)
    False -> Error(Nil)
  }
}

fn tuple_sub(tuple_a: #(Int, Int), tuple_b: #(Int, Int)) {
  #(tuple_a.0 - tuple_b.0, tuple_a.1 - tuple_b.1)
}

fn tuple_multiply(multiplier: Int, tuple: #(Int, Int)) {
  #(tuple.0 * multiplier, tuple.1 * multiplier)
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
