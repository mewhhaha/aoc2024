import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string

pub fn main() {
  let t = lines()

  let assert Ok(plots) = to_grid(t |> list.map(string.to_graphemes))
  let regions = to_regions(plots)

  let total_price =
    regions |> list.fold(0, fn(acc, v) { acc + calculate_price(v) })
  io.println(total_price |> int.to_string)
}

fn to_regions(plots: dict.Dict(#(Int, Int), String)) {
  do_to_regions([], plots)
}

fn do_to_regions(
  acc: List(List(#(Int, Int))),
  plots: dict.Dict(#(Int, Int), String),
) {
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
  start: #(Int, Int),
  value: String,
  plots: dict.Dict(#(Int, Int), String),
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

fn calculate_price(region: List(#(Int, Int))) {
  let area = list.length(region)

  let zoomed_in_region =
    region
    |> list.map(fn(v) { #(v.0 * 10, v.1 * 10) })

  let poles =
    zoomed_in_region
    |> list.flat_map(fn(v) {
      let offsets = [
        #(v.0 + 5, v.1 + 5),
        #(v.0 + 5, v.1 - 5),
        #(v.0 - 5, v.1 + 5),
        #(v.0 - 5, v.1 - 5),
      ]

      offsets |> list.map(fn(offset) { #(offset.0, offset.1) })
    })
    |> set.from_list
    |> set.to_list
  let corners = count_corners(poles, zoomed_in_region)

  corners * area
}

fn count_corners(poles: List(#(Int, Int)), region: List(#(Int, Int))) {
  let lookup = region |> set.from_list
  use acc, #(x, y) <- fn(f) { poles |> list.fold(0, f) }

  let diagonals =
    [#(x + 5, y + 5), #(x + 5, y - 5), #(x - 5, y + 5), #(x - 5, y - 5)]
    |> list.map(fn(v) { set.contains(lookup, v) })

  let corners = case diagonals {
    [True, False, False, False] -> {
      1
    }
    [False, True, False, False] -> {
      1
    }
    [False, False, True, False] -> {
      1
    }
    [False, False, False, True] -> {
      1
    }
    [False, True, True, True] -> {
      1
    }
    [True, False, True, True] -> {
      1
    }
    [True, True, False, True] -> {
      1
    }
    [True, True, True, False] -> {
      1
    }
    [True, False, False, True] -> {
      2
    }
    [False, True, True, False] -> {
      2
    }
    _ -> {
      0
    }
  }
  acc + corners
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
