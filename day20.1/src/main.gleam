import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/string

type Spot {
  Empty
  Wall
  Start
  End
}

pub fn main() {
  let assert [limit_raw, ..t] = lines()
  let assert Ok(limit) = limit_raw |> int.parse
  let assert Ok(carta) =
    t
    |> list.map(fn(line) { line |> string.to_graphemes |> list.map(parse_spot) })
    |> to_grid

  let positions = carta |> dict.to_list

  let assert Ok(start) = positions |> find_position_of_spot(Start)
  let assert Ok(end) = positions |> find_position_of_spot(End)

  let assert Ok(visited) = shortest_path(carta, start, end)

  let assert Ok(score) = visited |> dict.get(end)

  let cheats =
    visited
    |> dict.to_list
    |> list.combinations(2)
    |> list.filter_map(fn(v) {
      let assert [#(pos_a, score_a), #(pos_b, score_b)] = v

      case cheating_distance(pos_a, pos_b) {
        X(2) -> {
          let min_x = int.min(pos_a.0, pos_b.0)
          case carta |> dict.get(#(min_x + 1, pos_a.1)) {
            Ok(Wall) -> Ok(#(score_a, score_b, 2))
            _ -> Error(Nil)
          }
        }
        Y(2) -> {
          let min_y = int.min(pos_a.1, pos_b.1)
          case carta |> dict.get(#(pos_a.0, min_y + 1)) {
            Ok(Wall) -> Ok(#(score_a, score_b, 2))
            _ -> Error(Nil)
          }
        }
        X(3) -> {
          let min_x = int.min(pos_a.0, pos_b.0)

          let first_block = #(min_x + 1, pos_a.1)
          let second_block = #(min_x + 2, pos_a.1)

          let first_block_score = carta |> dict.get(first_block)
          let second_block_score = carta |> dict.get(second_block)

          case first_block_score, second_block_score {
            Ok(Wall), Ok(Wall) -> Ok(#(score_a, score_b, 3))
            _, _ -> Error(Nil)
          }
        }
        Y(3) -> {
          let min_y = int.min(pos_a.1, pos_b.1)
          let first_block = #(pos_a.0, min_y + 1)
          let second_block = #(pos_a.0, min_y + 2)

          let first_block_score = carta |> dict.get(first_block)
          let second_block_score = carta |> dict.get(second_block)

          case first_block_score, second_block_score {
            Ok(Wall), Ok(Wall) -> Ok(#(score_a, score_b, 3))
            _, _ -> Error(Nil)
          }
        }

        _ -> {
          Error(Nil)
        }
      }
    })
    |> list.filter_map(fn(v) {
      let #(score_a, score_b, distance) = v

      let big = int.max(score_a, score_b)
      let small = int.min(score_a, score_b)

      let saved_time = big - { small + distance }
      let cheating_score = score - saved_time

      // Uh, I'm getting the wrong result on test but worked on the real input...
      case saved_time >= limit {
        True -> Ok(#(cheating_score, saved_time))
        False -> Error(Nil)
      }
    })

  let result = cheats |> list.length

  io.println(result |> int.to_string)
}

type Cheat {
  X(Int)
  Y(Int)
  Nope
}

fn cheating_distance(a: #(Int, Int), b: #(Int, Int)) {
  let x_cheating_distance = int.absolute_value(a.0 - b.0)
  let y_cheating_distance = int.absolute_value(a.1 - b.1)

  case
    x_cheating_distance <= 3 && x_cheating_distance > 1 && a.1 == b.1,
    y_cheating_distance <= 3 && y_cheating_distance > 1 && a.0 == b.0
  {
    True, _ -> X(x_cheating_distance)
    _, True -> Y(y_cheating_distance)
    _, _ -> Nope
  }
}

fn find_position_of_spot(
  positions: List(#(#(Int, Int), Spot)),
  spot: Spot,
) -> Result(#(Int, Int), Nil) {
  positions
  |> list.find_map(fn(v) {
    case v.1 == spot {
      True -> Ok(v.0)
      False -> Error(Nil)
    }
  })
}

fn parse_spot(c: String) -> Spot {
  case c {
    "#" -> Wall
    "." -> Empty
    "S" -> Start
    "E" -> End
    _ -> panic as { "Invalid spot got: " <> c }
  }
}

fn shortest_path(
  carta: dict.Dict(#(Int, Int), Spot),
  start: #(Int, Int),
  end: #(Int, Int),
) {
  do_shortest_path(carta, end, dict.new(), [#(start, 0)])
}

fn do_shortest_path(
  carta: dict.Dict(#(Int, Int), Spot),
  end: #(Int, Int),
  visited: dict.Dict(#(Int, Int), Int),
  queue: List(#(#(Int, Int), Int)),
) {
  case queue {
    [#(position, _), ..] if position == end -> {
      Ok(visited)
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
          let not_visited = !{ visited |> dict.has_key(pos) }
          let is_empty = carta |> dict.get(pos) != Ok(Wall)

          not_visited && is_empty
        })

      let scored_adjacent =
        valid_adjacent
        |> list.map(fn(pos) { #(pos, score + 1) })

      let next_queue =
        bubble(tail, scored_adjacent, fn(a, b) { int.compare(a.1, b.1) })

      let next_visited =
        valid_adjacent
        |> list.fold(visited, fn(acc, pos) { dict.insert(acc, pos, score + 1) })

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
