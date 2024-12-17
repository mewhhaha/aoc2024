import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/set
import gleam/string

type Spot {
  Wall
  Empty
  Start
  End
}

pub fn main() {
  let t = lines()

  let assert Ok(carta) = t |> list.map(parse_spots) |> to_grid()

  let assert Ok(start) =
    carta |> dict.to_list |> list.find(fn(a) { a.1 == Start })
  let assert Ok(end) = carta |> dict.to_list |> list.find(fn(a) { a.1 == End })

  let result = shortest_path(carta, start.0, end.0)

  let result = result |> set.map(fn(v) { v.0 })

  print_grid(carta, fn(p, v) {
    case result |> set.contains(p) {
      True -> {
        "O"
      }
      False ->
        case v {
          Start -> {
            "S"
          }
          End -> {
            "E"
          }
          Wall -> {
            "#"
          }
          Empty -> {
            "."
          }
        }
    }
  })

  io.println(result |> set.size |> int.to_string)
}

fn shortest_path(
  carta: dict.Dict(#(Int, Int), Spot),
  start: #(Int, Int),
  end: #(Int, Int),
) {
  let visited = dict.from_list([])
  let scores = [#(start, #(1, 0), 0)]

  let ends =
    set.from_list([
      #(end, #(1, 0)),
      #(end, #(-1, 0)),
      #(end, #(0, 1)),
      #(end, #(0, -1)),
    ])

  do_shortest_path(carta, ends, Error(Nil), visited, scores)
}

type ShortestPath {
  ReachedEnd
  Visited
  NotVisited
}

fn do_shortest_path(
  carta: dict.Dict(#(Int, Int), Spot),
  ends: set.Set(#(#(Int, Int), #(Int, Int))),
  shortest_path: Result(Int, Nil),
  visited: dict.Dict(#(#(Int, Int), #(Int, Int)), Int),
  queue: List(#(#(Int, Int), #(Int, Int), Int)),
) {
  case queue {
    [#(position, direction, score), ..tail] -> {
      let is_end = ends |> set.contains(#(position, direction))
      let is_visited = visited |> dict.has_key(#(position, direction))

      let continue = case is_end, is_visited {
        True, _ -> {
          ReachedEnd
        }
        False, True -> {
          Visited
        }
        False, False -> {
          NotVisited
        }
      }

      case continue {
        ReachedEnd -> {
          backtrack(visited, #(position, direction))
        }
        Visited -> {
          do_shortest_path(carta, ends, shortest_path, visited, tail)
        }
        NotVisited -> {
          let adjacent =
            self_and_adjacent(direction, position, score)
            |> list.filter(fn(a) {
              let is_walkable = carta |> dict.get(a.0) != Ok(Wall)

              let is_not_too_long = case shortest_path {
                Ok(shortest_path_score) -> {
                  score <= shortest_path_score
                }
                Error(_) -> {
                  True
                }
              }

              is_walkable && is_not_too_long
            })

          let next_queue = bubble(tail, adjacent, compare_scores)

          let next_visited =
            visited |> dict.insert(#(position, direction), score)

          do_shortest_path(carta, ends, shortest_path, next_visited, next_queue)
        }
      }
    }
    [] -> {
      ends
    }
  }
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

fn backtrack(
  visited: dict.Dict(#(#(Int, Int), #(Int, Int)), Int),
  end: #(#(Int, Int), #(Int, Int)),
) {
  do_backtrack(set.new(), visited, end)
}

fn do_backtrack(
  acc: set.Set(#(#(Int, Int), #(Int, Int))),
  visited: dict.Dict(#(#(Int, Int), #(Int, Int)), Int),
  position: #(#(Int, Int), #(Int, Int)),
) {
  let back = #(#(tuple_sub(position.0, position.1), position.1), 1000)
  let left = #(#(position.0, #(-position.1.1, position.1.0)), 1)
  let right = #(#(position.0, #(position.1.1, -position.1.0)), 1)

  let adjacent = [back, left, right]

  let assert [result, ..] =
    adjacent
    |> list.map(fn(v) {
      case visited |> dict.get(v.0) {
        Ok(score) -> {
          #(v, score - v.1)
        }
        Error(_) -> {
          #(v, 9_999_999_999)
        }
      }
    })
    |> list.sort(fn(a, b) { int.compare(a.1, b.1) })
    |> list.chunk(fn(a) { a.1 })

  result
  |> list.fold(acc, fn(acc, v) {
    case v {
      #(next, 0) -> {
        acc |> set.insert(next.0) |> set.insert(position)
      }
      #(next, _) -> {
        do_backtrack(acc |> set.insert(position), visited, next.0)
      }
    }
  })
}

fn compare_scores(
  a: #(#(Int, Int), #(Int, Int), Int),
  b: #(#(Int, Int), #(Int, Int), Int),
) {
  int.compare(a.2, b.2)
}

fn self_and_adjacent(direction: #(Int, Int), position: #(Int, Int), score: Int) {
  let left_direction = #(-direction.1, direction.0)
  let right_direction = #(direction.1, -direction.0)

  let forward = #(tuple_add(position, direction), direction, 1 + score)
  let left = #(position, left_direction, 1000 + score)
  let right = #(position, right_direction, 1000 + score)

  [forward, left, right]
}

fn tuple_add(a: #(Int, Int), b: #(Int, Int)) {
  #(a.0 + b.0, a.1 + b.1)
}

fn tuple_sub(a: #(Int, Int), b: #(Int, Int)) {
  #(a.0 - b.0, a.1 - b.1)
}

fn bubble(
  l: List(value),
  values: List(value),
  compare: fn(value, value) -> order.Order,
) {
  do_bubble([], l, values, compare)
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

fn parse_spots(s: String) {
  s |> string.to_graphemes |> list.map(parse_spot)
}

fn parse_spot(s: String) {
  case s {
    "#" -> Wall
    "." -> Empty
    "S" -> Start
    "E" -> End
    _ -> panic as "Unknown spot: {s}"
  }
}

fn to_grid(lines: List(List(value))) {
  use row, y <- fn(f) { lines |> list.index_map(f) |> list.reduce(dict.merge) }

  use v, x <- fn(f) { row |> list.index_map(f) |> dict.from_list }

  #(#(x, y), v)
}

fn do_split_on(acc: List(value), l: List(value), value) {
  case l {
    [v, ..rest] if v == value -> {
      [acc |> list.reverse, ..do_split_on([], rest, value)]
    }
    [v, ..rest] -> {
      do_split_on([v, ..acc], rest, value)
    }
    [] -> {
      [acc |> list.reverse]
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
      do_lines([string.trim_end(v), ..acc])
    }
  }
}
