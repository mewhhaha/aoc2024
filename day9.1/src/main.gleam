import gleam/dict
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string

pub fn main() {
  let assert [t] = lines()

  let parsed = parse_memory(t)
  let defragmented = defragment(parsed)

  let assert Ok(result) =
    defragmented
    |> list.index_map(fn(v, i) { v * i })
    |> list.reduce(int.add)

  io.println(result |> int.to_string)
}

fn defragment(memory_layout: List(option.Option(Int))) {
  let numbers = memory_layout |> list.filter(option.is_some) |> list.length
  let memory = do_defragment([], memory_layout, memory_layout |> list.reverse)
  memory |> list.take(numbers)
}

fn do_defragment(
  acc: List(Int),
  left: List(option.Option(Int)),
  right: List(option.Option(Int)),
) {
  case left, right {
    [None, ..tail], [None, ..r] -> {
      do_defragment(acc, [None, ..tail], r)
    }
    [None, ..tail], [Some(head), ..r] -> {
      let new_acc = [head, ..acc]
      do_defragment(new_acc, tail, r)
    }
    [Some(head), ..tail], r -> {
      let new_acc = [head, ..acc]
      do_defragment(new_acc, tail, r)
    }
    _, _ -> acc |> list.reverse
  }
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
