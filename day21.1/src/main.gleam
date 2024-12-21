import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result

import gleam/order

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

type State {
  State(dirpads: List(#(Int, Int)), numpad: #(#(Int, Int), List(Numpad)))
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

  // let destinations = numpad |> dict_invert

  let is_end = fn(value: State) { value.numpad.1 == [] }
  let get_adjacent = fn(
    visited: dict.Dict(State, Int),
    value: State,
    score: Int,
  ) {
    [DL, DR, DU, DD, DPress]
    |> list.filter_map(fn(d) {
      use #(button, dirpads) <- result.try(press_button(
        dirpad,
        d,
        value.dirpads,
      ))
      case button {
        option.Some(DPress) -> {
          let assert Ok(output) = numpad |> dict.get(value.numpad.0)
          case value.numpad.1 {
            [head, ..tail] if head == output -> {
              let next_state = State(dirpads, #(value.numpad.0, tail))
              Ok(#(next_state, score + 1))
            }
            _ -> Error(Nil)
          }
        }
        option.Some(n) -> {
          let pos = move_position(value.numpad.0, n)
          use _ <- result.try(numpad |> dict.get(pos))
          Ok(#(
            State(dirpads: dirpads, numpad: #(pos, value.numpad.1)),
            score + 1,
          ))
        }
        _ -> {
          Ok(#(State(..value, dirpads: dirpads), score + 1))
        }
      }
    })
    |> list.filter(fn(v) {
      let already_visited = visited |> dict.get(v.0)
      case already_visited {
        Ok(_) -> False
        Error(_) -> True
      }
    })
  }

  let scores =
    t
    |> list.map(fn(s) {
      let #(code, n) = parse_code(s)
      let start = State([#(2, 0), #(2, 0)], #(#(2, 3), code))
      let assert Ok(score) = shortest_path(start, is_end, get_adjacent)
      n * score
    })
  let result = scores |> list.fold(0, int.add)

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

fn shortest_path(
  start: value,
  is_end: fn(value) -> Bool,
  get_adjacent: fn(dict.Dict(value, Int), value, Int) -> List(#(value, Int)),
) {
  do_shortest_path(is_end, dict.new(), [#(start, 0)], get_adjacent)
}

fn do_shortest_path(
  is_end: fn(value) -> Bool,
  visited: dict.Dict(value, Int),
  queue: List(#(value, Int)),
  get_adjacent: fn(dict.Dict(value, Int), value, Int) -> List(#(value, Int)),
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
      Ok(score)
    }
    False -> {
      let adjacent = get_adjacent(visited, position, score)

      let next_queue =
        bubble(tail, adjacent, fn(a, b) { int.compare(a.1, b.1) })

      let next_visited =
        adjacent
        |> list.fold(visited, fn(acc, n) { dict.insert(acc, n.0, n.1) })

      do_shortest_path(is_end, next_visited, next_queue, get_adjacent)
    }
  }
}

fn press_button(
  dirpad: dict.Dict(#(Int, Int), Dirpad),
  button: Dirpad,
  dirpads: List(#(Int, Int)),
) {
  case dirpads {
    [] -> {
      Ok(#(option.Some(button), dirpads))
    }
    [prev, ..tail] -> {
      case button {
        DPress -> {
          use button <- result.try(dirpad |> dict.get(prev))
          use #(b, dirpads) <- result.try(press_button(dirpad, button, tail))
          Ok(#(b, [prev, ..dirpads]))
        }
        n -> {
          let pos = move_position(prev, n)
          use _ <- result.try(dirpad |> dict.get(pos))
          Ok(#(option.None, [pos, ..tail]))
        }
      }
    }
  }
}

fn move_position(pos: #(Int, Int), n: Dirpad) -> #(Int, Int) {
  case n {
    DL -> {
      #(pos.0 - 1, pos.1)
    }
    DR -> {
      #(pos.0 + 1, pos.1)
    }
    DU -> {
      #(pos.0, pos.1 - 1)
    }
    DD -> {
      #(pos.0, pos.1 + 1)
    }
    DPress -> {
      panic as "DPress is not a valid offset"
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
