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

  let assert [n_raw, w_raw, h_raw] = string.split(bounds_raw, " ")
  let assert Ok(n) = int.parse(n_raw)
  let assert Ok(w) = int.parse(w_raw)
  let assert Ok(h) = int.parse(h_raw)

  let positions = positions_raw |> list.map(parse_position) |> list.take(n)

  let carta =
    {
      use y <- fn(f) { list.range(0, h) |> list.flat_map(f) }
      use x <- fn(f) { list.range(0, w) |> list.map(f) }
      #(#(x, y), Empty)
    }
    |> dict.from_list

  let corrupted_carta =
    positions
    |> list.fold(carta, fn(acc, pos) { dict.insert(acc, pos, Corrupted) })

  let start = #(0, 0)
  let end = #(w, h)

  print_grid(corrupted_carta, fn(_, v) {
    case v {
      Empty -> {
        "."
      }
      Corrupted -> {
        "#"
      }
    }
  })

  let assert Ok(result) = shortest_path(corrupted_carta, start, end)
  io.println(result |> int.to_string)
}

fn shortest_path(
  carta: dict.Dict(#(Int, Int), Spot),
  start: #(Int, Int),
  end: #(Int, Int),
) {
  do_shortest_path(carta, end, set.new(), [#(start, 0)])
}

fn do_shortest_path(
  carta: dict.Dict(#(Int, Int), Spot),
  end: #(Int, Int),
  visited: set.Set(#(Int, Int)),
  queue: List(#(#(Int, Int), Int)),
) {
  case queue {
    [#(position, score), ..] if position == end -> {
      Ok(score)
    }
    [#(position, score), ..tail] -> {
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
        |> list.map(fn(pos) { #(pos, score + 1) })

      let next_queue =
        bubble(tail, valid_adjacent, fn(a, b) { int.compare(a.1, b.1) })

      let next_visited =
        adjacent
        |> set.from_list()
        |> set.union(visited)

      do_shortest_path(carta, end, next_visited, next_queue)
    }
    [] -> {
      Error(Nil)
    }
  }
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

fn print_grid(
  map: dict.Dict(#(Int, Int), value),
  to_char: fn(#(Int, Int), value) -> String,
) {
  let result =
    map
    |> dict.to_list()
    |> list.sort(fn(a, b) { int.compare(a.0.1, b.0.1) })
    |> list.chunk(fn(a) { a.0.1 })
    |> list.map(fn(row) {
      row
      |> list.sort(fn(a, b) { int.compare(a.0.0, b.0.0) })
      |> list.map(fn(cell) { to_char(cell.0, cell.1) })
      |> string.join("")
    })

  result |> list.each(io.println)
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
