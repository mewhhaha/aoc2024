import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/string

type Calibration {
  Equation(Int, List(Int))
}

pub fn main() {
  let t = lines()

  let calibrations = t |> list.map(parse_line)

  let valid_calibrations = {
    use Equation(result, values) <- fn(f) { calibrations |> list.filter(f) }
    calibrate(values) |> list.any(fn(v) { v == result })
  }

  let valid_results =
    valid_calibrations
    |> list.map(fn(equation) {
      case equation {
        Equation(result, _) -> result
      }
    })
  let assert Ok(result) = valid_results |> list.reduce(int.add)

  io.println(result |> int.to_string)
}

fn calibrate(values: List(Int)) {
  let assert [v, ..rest] = values
  do_calibrate(v, rest)
}

fn do_calibrate(acc: Int, values: List(Int)) {
  case values {
    [] -> [acc]
    [v, ..rest] -> {
      do_calibrate(acc + v, rest) |> list.append(do_calibrate(acc * v, rest))
    }
  }
}

fn parse_line(line: String) {
  let assert [result_raw, ..values_raw] = line |> string.split(" ")

  let assert Ok(result) = int.parse(result_raw |> string.drop_end(1))

  let values =
    values_raw
    |> list.map(fn(v) {
      let assert Ok(n) = int.parse(v)

      n
    })

  Equation(result, values)
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
