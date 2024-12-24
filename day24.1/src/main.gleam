import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string

pub fn main() {
  let t = lines()

  let assert [defaults_raw, combinators_raw] = split_on(t, "")

  let defaults = defaults_raw |> list.map(parse_default) |> dict.from_list

  let combinators = combinators_raw |> list.map(parse_combinator)

  let final = solve(combinators, defaults)

  let result =
    final
    |> dict.filter(fn(k, _) { k |> string.starts_with("z") })
    |> dict.to_list
    |> list.sort(string.compare |> desc |> on(fst))
    |> list.map(snd)
    |> list.fold(0, fn(acc, v) {
      acc |> int.bitwise_shift_left(1) |> int.add(v)
    })

  io.println(result |> int.to_string)
}

fn desc(compare: fn(a, b) -> order.Order) {
  fn(a, b) { compare(b, a) }
}

fn on(compare: fn(b, b) -> order.Order, get: fn(a) -> b) {
  fn(a, b) { compare(get(a), get(b)) }
}

fn snd(tuple: #(a, b)) {
  tuple.1
}

fn fst(tuple: #(a, b)) {
  tuple.0
}

fn solve(
  combinators: List(
    fn(dict.Dict(String, Int)) -> Result(dict.Dict(String, Int), Nil),
  ),
  vars: dict.Dict(String, Int),
) {
  do_solve(combinators |> list.length, combinators, vars)
}

fn do_solve(
  prev_length: Int,
  combinators: List(
    fn(dict.Dict(String, Int)) -> Result(dict.Dict(String, Int), Nil),
  ),
  vars: dict.Dict(String, Int),
) {
  let next_combinators =
    combinators
    |> list.fold(vars, fn(acc, combinator) {
      combinator(acc) |> result.unwrap(acc)
    })

  let next_length = next_combinators |> dict.size
  case next_length == prev_length {
    True -> {
      vars
    }
    False -> {
      do_solve(next_length, combinators, next_combinators)
    }
  }
}

fn parse_default(line: String) {
  let assert [a, b] = string.split(line, ": ")
  let assert Ok(value) = int.parse(b)
  #(a, value)
}

fn parse_combinator(line: String) {
  let assert [input, var_output] = string.split(line, " -> ")
  let assert [var_a, op_raw, var_c] = string.split(input, " ")

  let op = case op_raw {
    "AND" -> fn(a, b) { a |> int.bitwise_and(b) }
    "OR" -> fn(a, b) { a |> int.bitwise_or(b) }
    "XOR" -> fn(a, b) { a |> int.bitwise_exclusive_or(b) }
    _ -> panic
  }

  fn(vars: dict.Dict(String, Int)) {
    use a <- result.try(vars |> dict.get(var_a))
    use b <- result.try(vars |> dict.get(var_c))

    let v = op(a, b)
    Ok(vars |> dict.insert(var_output, v))
  }
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
