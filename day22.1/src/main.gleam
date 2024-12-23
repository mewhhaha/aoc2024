import gleam/dict
import gleam/erlang
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/order
import gleam/result
import gleam/set
import gleam/string
import gleam/string_builder

pub fn main() {
  let t = lines()

  let numbers = {
    use s <- fn(f) { t |> list.map(f) }
    let assert Ok(n) = s |> int.parse
    n
  }

  let secret_numbers = {
    use n <- fn(f) { numbers |> list.map(f) }
    iterate(2000, n, next_secret_number)
  }

  let result = secret_numbers |> list.fold(0, int.add)

  io.println(result |> int.to_string)
}

fn iterate(times: Int, n: Int, f: fn(Int) -> Int) -> Int {
  case times {
    0 -> {
      n
    }
    _ -> {
      let next = f(n)
      iterate(times - 1, next, f)
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
