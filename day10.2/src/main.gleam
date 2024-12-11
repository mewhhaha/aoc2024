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
        Error(_) -> -1
      }
    })

  let starts =
    grid
    |> dict.filter(fn(_, v) { v == 0 })
    |> dict.keys()

  let assert Ok(result) =
    starts
    |> list.map(fn(start) {
      let memo = find_high_points(grid, start)
      let assert Ok(result) = dict.get(memo, start)
      result
    })
    |> list.reduce(int.add)

  io.println(result |> int.to_string)
}

fn find_high_points(grid: dict.Dict(#(Int, Int), Int), key: #(Int, Int)) {
  do_find_high_points(dict.new(), grid, key)
}

fn do_find_high_points(
  memo: dict.Dict(#(Int, Int), Int),
  grid: dict.Dict(#(Int, Int), Int),
  key: #(Int, Int),
) {
  case dict.get(memo, key), dict.get(grid, key) {
    Ok(_), _ -> {
      memo
    }
    _, Ok(9) -> {
      memo |> dict.insert(key, 1)
    }
    _, Ok(elevation) -> {
      let adjacent =
        set.from_list([
          #(key.0 - 1, key.1),
          #(key.0 + 1, key.1),
          #(key.0, key.1 - 1),
          #(key.0, key.1 + 1),
        ])
        |> set.delete(key)

      let is_higher_elevation = fn(k) {
        case dict.get(grid, k) {
          Ok(adjacent_elevation) -> adjacent_elevation == elevation + 1
          _ -> False
        }
      }

      let visited = memo |> dict.keys() |> set.from_list

      let visitable =
        adjacent
        |> set.filter(is_higher_elevation)

      let next_memo =
        visitable
        |> set.difference(visited)
        |> set.fold(memo, fn(m, k) { do_find_high_points(m, grid, k) })

      let score =
        visitable
        |> set.fold(0, fn(acc, k) {
          case dict.get(next_memo, k) {
            Ok(v) -> acc + v
            Error(_) -> acc
          }
        })

      next_memo |> dict.insert(key, score)
    }
    _, _ -> {
      memo |> dict.insert(key, 0)
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
