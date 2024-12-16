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

  let assert Ok(result) = shortest_path(carta, start.0, end.0)

  io.println(result |> int.to_string)
}

fn shortest_path(
  carta: dict.Dict(#(Int, Int), Spot),
  start: #(Int, Int),
  end: #(Int, Int),
) {
  let visited = set.from_list([#(start, #(1, 0))])
  let scores = [#(start, #(1, 0), 0)]

  do_shortest_path(carta, end, visited, scores)
}

fn do_shortest_path(
  carta: dict.Dict(#(Int, Int), Spot),
  end: #(Int, Int),
  visited: set.Set(#(#(Int, Int), #(Int, Int))),
  scores: List(#(#(Int, Int), #(Int, Int), Int)),
) {
  // case scores |> list.sort(fn(a, b) { int.compare(a.2, b.2) }) == scores {
  //   True -> {
  //     Nil
  //   }
  //   False -> {
  //     io.debug(scores)
  //     io.debug(scores |> list.sort(fn(a, b) { int.compare(a.2, b.2) }))
  //     panic
  //   }
  // }

  case scores {
    [#(position, _, score), ..] if position == end -> Ok(score)
    [#(position, direction, score), ..tail] -> {
      let adjacent =
        [#(1, 0), #(-1, 0), #(0, 1), #(0, -1)]
        |> list.map(fn(d) {
          case d == direction {
            True -> #(#(position.0 + d.0, position.1 + d.1), d, 1 + score)
            False -> #(
              #(position.0 + d.0, position.1 + d.1),
              d,
              1 + 1000 + score,
            )
          }
        })
        |> list.filter(fn(a) {
          let already_visited = visited |> set.contains(#(a.0, a.1))
          let cannot_go = carta |> dict.get(a.0) == Ok(Wall)

          !already_visited && !cannot_go
        })
        |> list.sort(fn(a, b) { int.compare(a.2, b.2) })

      let next_scores =
        bubble(tail, adjacent, fn(a, b) { int.compare(a.2, b.2) })

      let next_visited = visited |> set.insert(#(position, direction))

      do_shortest_path(carta, end, next_visited, next_scores)
    }
    [] -> {
      Error(Nil)
    }
  }
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

// fn print_grid(map: dict.Dict(#(Int, Int), value), to_char: fn(value) -> String) {
//   let result =
//     map
//     |> dict.to_list()
//     |> list.sort(fn(a, b) { int.compare(a.0.1, b.0.1) })
//     |> list.chunk(fn(a) { a.0.1 })
//     |> list.map(fn(row) {
//       row
//       |> list.sort(fn(a, b) { int.compare(a.0.0, b.0.0) })
//       |> list.map(fn(cell) { cell.1 |> to_char })
//       |> string.join("")
//     })

//   result |> list.each(io.println)
// }

fn to_grid(lines: List(List(value))) {
  use row, y <- fn(f) { lines |> list.index_map(f) |> list.reduce(dict.merge) }

  use v, x <- fn(f) { row |> list.index_map(f) |> dict.from_list }

  #(#(x, y), v)
}

// fn split_on(l: List(value), value) {
//   do_split_on([], l, value)
// }

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
