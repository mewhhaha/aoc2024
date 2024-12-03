import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/string

pub fn main() {
  let t = lines()

  let single_string = t |> list.map(string.trim) |> string.join("")

  let options = regexp.Options(case_insensitive: False, multi_line: False)
  let assert Ok(re_mul) = regexp.compile("^mul\\(([0-9]+),([0-9]+)\\)", options)

  let assert Left(muls) =
    compute_muls(single_string, Muls(muls: [], do: True, re_mul: re_mul))

  let assert Ok(result) =
    muls
    |> list.map(fn(mul) { mul.0 * mul.1 })
    |> list.reduce(int.add)

  io.println(int.to_string(result))
}

type State {
  Muls(muls: List(#(Int, Int)), do: Bool, re_mul: regexp.Regexp)
}

type Either(a, b) {
  Left(a)
  Right(b)
}

fn either_try(e: Either(a, b), f: fn(b) -> Either(a, b)) -> Either(a, b) {
  case e {
    Left(a) -> Left(a)
    Right(b) -> f(b)
  }
}

fn compute_muls(s: String, state: State) -> Either(List(#(Int, Int)), Nil) {
  use _ <- either_try({
    case s, state.do {
      "", _ -> Left(state.muls)
      "do()" <> rest, _ -> {
        compute_muls(rest, Muls(..state, do: True))
      }
      "don't()" <> rest, _ -> {
        compute_muls(rest, Muls(..state, do: False))
      }
      _, False -> compute_muls(string.drop_start(s, 1), state)
      _, True -> Right(Nil)
    }
  })

  let matches = regexp.scan(state.re_mul, s)
  case matches {
    [match] -> {
      let assert [Some(a), Some(b)] = match.submatches
      let assert Ok(ia) = int.parse(a)
      let assert Ok(ib) = int.parse(b)
      compute_muls(
        string.drop_start(s, string.length(match.content)),
        Muls(..state, muls: state.muls |> list.append([#(ia, ib)])),
      )
    }
    _ -> {
      compute_muls(string.drop_start(s, 1), state)
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
      do_lines([v, ..acc])
    }
  }
}
