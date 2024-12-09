import gleam/erlang
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

pub fn main() {
  let assert [t] = lines()

  let parsed = parse_memory(t)

  let defragmented = defragment(parsed)

  let assert Ok(result) =
    defragmented
    |> list.index_map(fn(v, i) {
      case v {
        File(v) -> v * i
        _ -> 0
      }
    })
    |> list.reduce(int.add)

  io.println(result |> int.to_string)
}

fn defragment(memory_layout: List(option.Option(Int))) {
  let chunked =
    memory_layout
    |> list.map(fn(v) {
      case v {
        None -> Free
        Some(v) -> File(v)
      }
    })
    |> list.chunk(function.identity)
  do_defragment([], chunked)
}

type Memory {
  Moved
  Free
  File(Int)
}

// lol so slow, so inefficient
fn do_defragment(acc: List(Memory), left: List(List(Memory))) {
  case left {
    [] -> acc |> list.reverse
    [head, ..tail] -> {
      case head {
        [Free, ..] -> {
          let space = list.length(head)

          let replaced =
            tail
            |> list.reverse
            |> find_and_replace(
              fn(v) {
                case v |> list.first {
                  Ok(File(_)) -> list.length(v) <= space
                  _ -> False
                }
              },
              fn(prev) { list.repeat(Moved, list.length(prev)) },
            )
          case replaced {
            Ok(#(value, with_replacement)) -> {
              do_defragment([value, acc] |> list.flatten, [
                head |> list.drop(list.length(value)),
                ..list.reverse(with_replacement)
              ])
            }
            _ -> {
              do_defragment([head, acc] |> list.flatten, tail)
            }
          }
        }
        _ -> {
          do_defragment([head, acc] |> list.flatten, tail)
        }
      }
    }
  }
}

fn find_and_replace(
  l: List(value),
  f: fn(value) -> Bool,
  replacement: fn(value) -> value,
) {
  let found =
    l |> list.index_map(fn(v, i) { #(v, i) }) |> list.find(fn(v) { f(v.0) })
  use #(value, index) <- result.try(found)
  let with_replacement =
    [l |> list.take(index), [replacement(value)], l |> list.drop(index + 1)]
    |> list.flatten

  Ok(#(value, with_replacement))
}

type MemoryDescriptor {
  Compressed(order: Int, used: Int, free: Int)
}

fn parse_memory(line: String) -> List(option.Option(Int)) {
  let memory_layout =
    line
    |> string.split("")
    |> list.sized_chunk(2)
    |> list.index_map(parse_chunk)

  do_parse_memory([], memory_layout)
}

fn do_parse_memory(
  acc: List(option.Option(Int)),
  compressed: List(MemoryDescriptor),
) -> List(option.Option(Int)) {
  case compressed {
    [] -> acc |> list.reverse
    [Compressed(order: order, used: used, free: free), ..tail] -> {
      let used_space = list.repeat(Some(order), used)
      let free_space = list.repeat(None, free)

      let new_acc = [free_space, used_space, acc] |> list.flatten
      do_parse_memory(new_acc, tail)
    }
  }
}

fn parse_chunk(chunk: List(String), i) {
  case chunk {
    [a] -> {
      let assert Ok(ia) = int.parse(a)
      Compressed(order: i, used: ia, free: 0)
    }
    [a, b] -> {
      let assert Ok(ia) = int.parse(a)
      let assert Ok(ib) = int.parse(b)
      Compressed(order: i, used: ia, free: ib)
    }
    _ -> {
      panic as "Invalid chunk"
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
