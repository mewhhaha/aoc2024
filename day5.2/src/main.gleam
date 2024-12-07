import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/string

pub fn main() {
  let t = lines()

  let assert [validator_rows, update_rows] = t |> split_on("")

  let validators = validator_rows |> list.map(parse_validator)

  let updates = update_rows |> list.map(parse_update)

  let invalid_updates = {
    use update <- fn(f) { updates |> list.filter(f) }
    use validator <- fn(f) { validators |> list.any(f) }

    !validator(update)
  }

  let validate_update = fn(update) {
    use validator <- fn(f) { validators |> list.all(f) }
    validator(update)
  }

  let sorted_updates = {
    use update <- fn(f) { invalid_updates |> list.map(f) }

    use #(a, b) <- fn(f) { update |> list.sort(fn(a, b) { f(#(a, b)) }) }

    case validate_update([a, b]), validate_update([b, a]) {
      True, True -> order.Eq
      True, False -> order.Lt
      False, True -> order.Gt
      False, False -> order.Eq
    }
  }

  let mid_numbers = get_mid_numbers(sorted_updates)

  let assert Ok(result) = mid_numbers |> list.reduce(int.add)

  io.println(result |> int.to_string)
}

fn get_mid_numbers(updates: List(List(Int))) {
  use update <- fn(f) { updates |> list.map(f) }
  let length = update |> list.length
  let mid = length / 2

  let assert Ok(n) = update |> list.drop(mid) |> list.first

  n
}

fn parse_validator(str: String) {
  let assert [a_raw, b_raw] = str |> string.split("|")

  let assert Ok(a) = a_raw |> int.parse
  let assert Ok(b) = b_raw |> int.parse

  fn(l: List(Int)) {
    case index_of(l, a), index_of(l, b) {
      Ok(ia), Ok(ib) -> {
        ia < ib
      }
      _, _ -> {
        True
      }
    }
  }
}

fn parse_update(str: String) {
  use n_raw <- fn(f) { str |> string.split(",") |> list.map(f) }
  let assert Ok(n) = int.parse(n_raw)
  n
}

fn index_of(l: List(value), value) {
  do_index_of(0, l, value)
}

fn do_index_of(acc: Int, l: List(value), value) {
  case l {
    [v, ..] if v == value -> {
      Ok(acc)
    }
    [_, ..rest] -> {
      do_index_of(acc + 1, rest, value)
    }
    [] -> {
      Error("not found")
    }
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
