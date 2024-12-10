import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string

pub fn main() {
  let t = lines()

  let assert Ok(grid_graphemes) =
    t
    |> list.map(string.to_graphemes)
    |> to_grid()

  let grid =
    grid_graphemes
    |> dict.map_values(fn(_, v) {
      case int.parse(v) {
        Ok(i) -> i
        Error(_) -> 11
      }
    })

  let starts =
    grid
    |> dict.filter(fn(_, v) { v == 0 })
    |> dict.keys()

  let assert Ok(result) =
    starts
    |> list.map(fn(start) {
      let high_points = find_high_points(grid, start)
      high_points |> set.size
    })
    |> list.reduce(int.add)

  io.println(result |> int.to_string)
}

fn find_high_points(grid: dict.Dict(#(Int, Int), Int), key: #(Int, Int)) {
  do_find_high_points(set.new(), grid, set.new(), [key])
}

fn do_find_high_points(
  acc: set.Set(#(Int, Int)),
  grid: dict.Dict(#(Int, Int), Int),
  visited: set.Set(#(Int, Int)),
  to_visit: List(#(Int, Int)),
) {
  case to_visit {
    [] -> {
      acc
    }
    [key, ..rest] -> {
      let adjacent =
        set.from_list([
          #(key.0 - 1, key.1),
          #(key.0 + 1, key.1),
          #(key.0, key.1 - 1),
          #(key.0, key.1 + 1),
        ])

      let assert Ok(elevation) = dict.get(grid, key)
      let next_visited = visited |> set.insert(key)

      let next_to_visit =
        adjacent
        |> set.difference(next_visited)
        |> set.filter(fn(k) {
          case dict.get(grid, k) {
            Ok(adjacent_elevation) -> {
              let difference = adjacent_elevation - elevation
              difference == 1
            }
            _ -> False
          }
        })
        |> set.union(set.from_list(rest))
        |> set.to_list

      let next_acc = {
        case elevation {
          9 -> acc |> set.insert(key)
          _ -> acc
        }
      }

      do_find_high_points(next_acc, grid, next_visited, next_to_visit)
    }
  }
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
