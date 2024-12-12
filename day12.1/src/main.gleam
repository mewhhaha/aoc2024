import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/string

type Position =
  #(Int, Int)

pub fn main() {
  let t = lines()

  let assert Ok(plots) = to_grid(t |> list.map(string.to_graphemes))
  let regions = to_regions(plots)

  let total_price =
    regions |> list.fold(0, fn(acc, v) { acc + calculate_price(v) })
  io.println(total_price |> int.to_string)
}

fn to_regions(plots: dict.Dict(Position, String)) {
  do_to_regions([], plots)
}

fn do_to_regions(acc: List(List(Position)), plots: dict.Dict(Position, String)) {
  case plots |> dict.to_list |> list.first {
    Ok(#(k, v)) -> {
      let #(region, next_plots) = extract_region(k, v, plots)
      do_to_regions([region, ..acc], next_plots)
    }
    Error(_) -> {
      acc
    }
  }
}

fn extract_region(
  start: Position,
  value: String,
  plots: dict.Dict(Position, String),
) {
  case plots |> dict.get(start) {
    Ok(w) if w == value -> {
      let adjacent = [
        #(start.0 + 1, start.1),
        #(start.0 - 1, start.1),
        #(start.0, start.1 + 1),
        #(start.0, start.1 - 1),
      ]

      let plots = plots |> dict.delete(start)

      let result = {
        use #(acc, plots), v <-
          fn(f) { adjacent |> list.fold(#([start], plots), f) }

        let #(region, plots) = extract_region(v, value, plots)

        #(region |> list.append(acc), plots)
      }

      result
    }
    _ -> {
      #([], plots)
    }
  }
}

fn calculate_price(t: List(Position)) {
  let area = list.length(t)
  let max_fences = area * 4

  let combinations = list.combinations(t, 2)

  let fences =
    combinations
    |> list.fold(max_fences, fn(acc, v) {
      let assert [#(x1, y1), #(x2, y2)] = v
      let distance = int.absolute_value(x1 - x2) + int.absolute_value(y1 - y2)

      case distance {
        1 -> acc - 2
        _ -> acc
      }
    })
  fences * area
}

fn to_grid(lines: List(List(value))) {
  use row, y <- fn(f) { lines |> list.index_map(f) |> list.reduce(dict.merge) }

  use v, x <- fn(f) { row |> list.index_map(f) |> dict.from_list }

  #(#(x, y), v)
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
