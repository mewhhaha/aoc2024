import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/set
import gleam/string

type Spot {
  Empty
  Corrupted
}

pub fn main() {
  let assert [bounds_raw, ..positions_raw] = lines()

  let assert [w_raw, h_raw] = string.split(bounds_raw, " ")
  let assert Ok(w) = int.parse(w_raw)
  let assert Ok(h) = int.parse(h_raw)

  let positions = positions_raw |> list.map(parse_position)
  let carta =
    {
      use y <- fn(f) { list.range(0, h) |> list.flat_map(f) }
      use x <- fn(f) { list.range(0, w) |> list.map(f) }
      #(#(x, y), Empty)
    }
    |> dict.from_list

  let start = #(0, 0)
  let end = #(w, h)

  let assert Ok(result) =
    find_first_blocking_position(positions, carta, start, end)

  io.println(result |> format_position)
}

fn find_first_blocking_position(
  positions: List(#(Int, Int)),
  carta: dict.Dict(#(Int, Int), Spot),
  start: #(Int, Int),
  end: #(Int, Int),
) {
  case positions {
    [pos, ..rest] -> {
      let corrupted_carta = carta |> dict.insert(pos, Corrupted)
      case shortest_path(corrupted_carta, start, end) {
        Error(_) -> Ok(pos)
        Ok(_) -> find_first_blocking_position(rest, corrupted_carta, start, end)
      }
    }
    [] -> {
      Error(Nil)
    }
  }
}

fn format_position(pos: #(Int, Int)) -> String {
  let x = pos.0 |> int.to_string
  let y = pos.1 |> int.to_string

  x <> "," <> y
}

fn shortest_path(
  carta: dict.Dict(#(Int, Int), Spot),
  start: #(Int, Int),
  end: #(Int, Int),
) {
  do_shortest_path(carta, end, set.new(), [#(start, 0, g_score(start, end))])
}

fn do_shortest_path(
  carta: dict.Dict(#(Int, Int), Spot),
  end: #(Int, Int),
  visited: set.Set(#(Int, Int)),
  queue: List(#(#(Int, Int), Int, Int)),
) {
  case queue {
    [#(position, score, _), ..] if position == end -> {
      Ok(score)
    }
    [#(position, score, _), ..tail] -> {
      let adjacent = [
        #(position.0 + 1, position.1),
        #(position.0 - 1, position.1),
        #(position.0, position.1 + 1),
        #(position.0, position.1 - 1),
      ]

      let valid_adjacent =
        adjacent
        |> list.filter(fn(pos) {
          let not_visited = !set.contains(visited, pos)
          let is_empty = dict.get(carta, pos) == Ok(Empty)

          not_visited && is_empty
        })

      let scored_adjacent =
        valid_adjacent
        |> list.map(fn(pos) { #(pos, score + 1, g_score(pos, end)) })

      let next_queue =
        bubble(tail, scored_adjacent, fn(a, b) { int.compare(a.2, b.2) })

      let next_visited =
        valid_adjacent
        |> list.fold(visited, fn(acc, pos) { set.insert(acc, pos) })

      do_shortest_path(carta, end, next_visited, next_queue)
    }
    [] -> {
      Error(Nil)
    }
  }
}

fn g_score(pos: #(Int, Int), end: #(Int, Int)) -> Int {
  let dx = pos.0 - end.0
  let dy = pos.1 - end.1

  dx * dx + dy * dy
}

fn bubble(
  sorted_list: List(value),
  values: List(value),
  compare: fn(value, value) -> order.Order,
) {
  do_bubble([], sorted_list, values, compare)
}

fn do_bubble(
  acc: List(value),
  l: List(value),
  values: List(value),
  compare: fn(value, value) -> order.Order,
) {
  case l, values {
    [head, ..tail], [value, ..rest] -> {
      case compare(value, head) {
        order.Lt -> {
          let next_acc = [value, ..acc]
          do_bubble(next_acc, l, rest, compare)
        }
        _ -> {
          do_bubble([head, ..acc], tail, values, compare)
        }
      }
    }
    tail, [] -> {
      acc |> list.reverse |> list.append(tail)
    }
    [], values -> {
      let vals = acc |> list.reverse |> list.append(values)
      vals
    }
  }
}

fn parse_position(s: String) -> #(Int, Int) {
  let assert [x_raw, y_raw] = string.split(s, ",")

  let assert Ok(x) = int.parse(x_raw)
  let assert Ok(y) = int.parse(y_raw)

  #(x, y)
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
