import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/string

pub fn main() {
  let t = lines()

  let numbers = {
    use s <- fn(f) { t |> list.map(f) }
    let assert Ok(n) = s |> int.parse
    n
  }

  let change_rates = {
    use n <- fn(f) { numbers |> list.map(f) }
    let ns = iterate(2000, n, next_secret_number)
    change_rates(ns)
  }

  let bananas_by_sequences = {
    use acc, cr <- fn(f) { change_rates |> list.fold(dict.new(), f) }
    let d = cr |> four_sequences
    acc |> dict.combine(d, fn(v1, v2) { v1 + v2 })
  }

  let result = bananas_by_sequences |> dict.values |> list.fold(0, int.max)

  io.println(result |> int.to_string)
}

fn four_sequences(ns: List(#(Int, Int))) {
  do_four_sequences(dict.new(), ns)
}

fn do_four_sequences(acc: dict.Dict(String, Int), ns: List(#(Int, Int))) {
  case ns {
    [n1, n2, n3, n4, ..tail] -> {
      let hash =
        [n1.1, n2.1, n3.1, n4.1] |> list.map(int.to_string) |> string.join("")

      let next_acc =
        acc
        |> dict.upsert(hash, fn(v) {
          case v {
            option.None -> n4.0
            option.Some(v) -> v
          }
        })
      do_four_sequences(next_acc, [n2, n3, n4, ..tail])
    }
    _ -> acc
  }
}

fn change_rates(ns: List(Int)) -> List(#(Int, Int)) {
  do_change_rates([], ns)
}

fn do_change_rates(acc: List(#(Int, Int)), ns: List(Int)) -> List(#(Int, Int)) {
  case ns {
    [n1, n2, ..tail] -> {
      let v1 = n1 % 10
      let v2 = n2 % 10
      let change_rate = v2 - v1

      do_change_rates([#(v2, change_rate), ..acc], [n2, ..tail])
    }
    _ -> acc |> list.reverse
  }
}

fn iterate(times: Int, n: Int, f: fn(Int) -> Int) -> List(Int) {
  do_iterate([], times, n, f)
}

fn do_iterate(
  acc: List(Int),
  times: Int,
  n: Int,
  f: fn(Int) -> Int,
) -> List(Int) {
  let next_acc = [n, ..acc]
  case times {
    0 -> {
      next_acc |> list.reverse
    }
    _ -> {
      let next = f(n)
      do_iterate(next_acc, times - 1, next, f)
    }
  }
}

fn next_secret_number(prev: Int) -> Int {
  let first = prev * 64 |> mix(prev) |> prune

  let second = first / 32 |> mix(first) |> prune

  let third = second * 2048 |> mix(second) |> prune

  third
}

fn mix(a: Int, secret_number: Int) -> Int {
  a |> int.bitwise_exclusive_or(secret_number)
}

fn prune(secret_number: Int) -> Int {
  secret_number % 16_777_216
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
