import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/order
import gleam/result
import gleam/string

type Dirpad {
  DL
  DR
  DU
  DD
  DPress
}

type Numpad {
  N1
  N2
  N3
  N4
  N5
  N6
  N7
  N8
  N9
  N0
  NA
}

pub fn main() {
  let t = lines()

  let assert Ok(numpad) =
    [
      [N7, N8, N9],
      [N4, N5, N6],
      [N1, N2, N3],
      [
        // Deleting this NA after since it's empty
        NA,
        N0,
        NA,
      ],
    ]
    |> to_grid()
    |> result.map(fn(d) { d |> dict.delete(#(0, 3)) })

  let assert Ok(dirpad) =
    [
      [
        // Deleting this DPress after since it's empty
        DPress,
        DU,
        DPress,
      ],
      [DL, DD, DR],
    ]
    |> to_grid()
    |> result.map(fn(d) { d |> dict.delete(#(0, 0)) })

  let results = {
    use s <- fn(f) { t |> list.map(f) }
    let #(code, n) = parse_code(s)

    let assert Ok(path) = shortest_dirpad_path(#(#(3, 3), code), numpad)

    // I have a bug somewhere, but,
    // process each instruction one at a time for each level
    // and memoize the results once you reach the end
    // then use the memo to speed this up
    let full_code =
      list.range(0, 1)
      |> list.fold(to_directions(path), fn(acc, _) {
        let assert Ok(next_path) = shortest_dirpad_path(#(#(2, 0), acc), dirpad)

        next_path |> to_directions
      })

    io.debug(format_dirpad(full_code))

    let length = full_code |> list.length
    length * n
  }

  let result = results |> list.fold(0, int.add)

  io.println(result |> int.to_string)
}

fn parse_code(s: String) -> #(List(Numpad), Int) {
  let code =
    s
    |> string.to_graphemes()
    |> list.map(fn(c) {
      case c {
        "0" -> N0
        "1" -> N1
        "2" -> N2
        "3" -> N3
        "4" -> N4
        "5" -> N5
        "6" -> N6
        "7" -> N7
        "8" -> N8
        "9" -> N9
        "A" -> NA
        _ -> panic as "Invalid code"
      }
    })
  let assert Ok(num) =
    s
    |> string.to_graphemes
    |> list.filter(is_digit)
    |> list.drop_while(fn(c) { c == "0" })
    |> string.join("")
    |> int.parse

  #(code, num)
}

fn format_dirpad(dirpad: List(Dirpad)) -> String {
  dirpad
  |> list.map(fn(d) {
    case d {
      DPress -> "A"
      DL -> "<"
      DR -> ">"
      DU -> "^"
      DD -> "v"
    }
  })
  |> string.join("")
}

fn is_digit(c: String) -> Bool {
  case c {
    "0" -> True
    "1" -> True
    "2" -> True
    "3" -> True
    "4" -> True
    "5" -> True
    "6" -> True
    "7" -> True
    "8" -> True
    "9" -> True
    _ -> False
  }
}

fn to_directions(path: List(#(#(Int, Int), List(value)))) -> List(Dirpad) {
  do_to_directions([], path)
}

fn do_to_directions(
  acc: List(Dirpad),
  path: List(#(#(Int, Int), List(value))),
) -> List(Dirpad) {
  case path {
    [n1, n2, ..rest] -> {
      let direction = get_direction(n1, n2)
      do_to_directions([direction, ..acc], [n2, ..rest])
    }
    _ -> {
      acc |> list.reverse
    }
  }
}

fn get_direction(
  n1: #(#(Int, Int), List(value)),
  n2: #(#(Int, Int), List(value)),
) -> Dirpad {
  let #(x1, y1) = n1.0
  let #(x2, y2) = n2.0
  let dx = x2 - x1
  let dy = y2 - y1
  case dx, dy {
    -1, 0 -> DL
    1, 0 -> DR
    0, -1 -> DU
    0, 1 -> DD
    0, 0 -> DPress
    _, _ -> panic
  }
}

fn shortest_dirpad_path(
  start: #(#(Int, Int), List(value)),
  pad: dict.Dict(#(Int, Int), value),
) {
  shortest_path(start, fn(v) { v.1 == [] }, fn(visited, v, score) {
    let #(position, code) = v

    case pad |> dict.get(position), code {
      Ok(n1), [n2, ..tail] if n1 == n2 -> {
        [#(#(position, tail), score + 1)]
      }
      _, _ -> {
        [
          #(#(position.0 + 1, position.1), code),
          #(#(position.0 - 1, position.1), code),
          #(#(position.0, position.1 - 1), code),
          #(#(position.0, position.1 + 1), code),
        ]
        |> list.filter(fn(v) {
          let already_visited = visited |> dict.get(v)
          case already_visited {
            Ok(_) -> False
            Error(_) -> True
          }
        })
        |> list.filter(fn(v) { pad |> dict.has_key(v.0) })
        |> list.map(fn(v) { #(v, score + 1 + { code |> list.length } * 100) })
      }
    }
  })
}

fn shortest_path(
  start: value,
  is_end: fn(value) -> Bool,
  get_adjacent: fn(dict.Dict(value, #(option.Option(value), Int)), value, Int) ->
    List(#(value, Int)),
) {
  do_shortest_path(
    is_end,
    [#(start, #(option.None, 0))] |> dict.from_list,
    [#(start, 0)],
    get_adjacent,
  )
}

fn do_shortest_path(
  is_end: fn(value) -> Bool,
  visited: dict.Dict(value, #(option.Option(value), Int)),
  queue: List(#(value, Int)),
  get_adjacent: fn(dict.Dict(value, #(option.Option(value), Int)), value, Int) ->
    List(#(value, Int)),
) {
  use #(#(position, score), tail) <- result.try({
    case queue {
      [] -> {
        Error(Nil)
      }
      [head, ..tail] -> {
        Ok(#(head, tail))
      }
    }
  })

  case is_end(position) {
    True -> {
      Ok(backtrack(visited, position))
    }
    False -> {
      let adjacent = get_adjacent(visited, position, score)

      let next_queue =
        bubble(tail, adjacent, fn(a, b) { int.compare(a.1, b.1) })

      let next_visited =
        adjacent
        |> list.fold(visited, fn(acc, n) {
          acc |> dict.insert(n.0, #(option.Some(position), n.1))
        })

      do_shortest_path(is_end, next_visited, next_queue, get_adjacent)
    }
  }
}

fn backtrack(
  visited: dict.Dict(value, #(option.Option(value), Int)),
  end: value,
) {
  do_backtrack(visited, end, [])
}

fn do_backtrack(
  visited: dict.Dict(value, #(option.Option(value), Int)),
  current: value,
  acc: List(value),
) {
  let assert Ok(#(parent, _)) = visited |> dict.get(current)
  case parent {
    option.Some(prev) -> {
      do_backtrack(visited, prev, [current, ..acc])
    }
    option.None -> {
      [current, ..acc]
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
