import gleam/dict
import gleam/erlang
import gleam/io
import gleam/list
import gleam/set
import gleam/string

pub fn main() {
  let t = lines()

  let connections =
    t
    |> list.flat_map(fn(line) {
      let assert [a, b] = line |> string.split("-")
      [#(a, b), #(b, a)]
    })
    |> list.group(fn(v) { v.0 })
    |> dict.map_values(fn(_, v) {
      v |> list.map(fn(v) { v.1 }) |> set.from_list
    })

  let max_size = connections |> dict.size
  let assert Ok(network) =
    iterate_until(#(3, []), fn(prev) {
      let #(network_length, last_network) = prev

      case network_length >= max_size {
        True -> Ok(last_network)

        False -> {
          let valid =
            connections
            |> dict.keys
            |> list.find_map(fn(key) {
              has_valid_network_of_size(connections, key, network_length)
            })

          case valid {
            Ok(network) -> Error(#(network_length + 1, network))
            Error(_) -> Ok(last_network)
          }
        }
      }
    })

  let result = network |> list.sort(string.compare) |> string.join(",")
  io.println(result)
}

fn iterate_until(b, f: fn(b) -> Result(a, b)) -> Result(a, b) {
  case f(b) {
    Error(b) -> iterate_until(b, f)
    Ok(a) -> Ok(a)
  }
}

fn has_valid_network_of_size(
  connections: dict.Dict(String, set.Set(String)),
  c0: String,
  size: Int,
) {
  let assert Ok(adjacent) = connections |> dict.get(c0)
  let combinations = adjacent |> set.to_list |> list.combinations(size - 1)
  use cs <- fn(f) { combinations |> list.find_map(f) }

  let all = [c0, ..cs] |> set.from_list
  let permutations =
    all
    |> set.to_list
    |> list.map(fn(v) { #(v, all |> set.delete(v)) })

  case
    permutations
    |> list.all(fn(v) {
      let #(head, tail) = v

      let assert Ok(adj_head) = connections |> dict.get(head)
      let intersection = tail |> set.intersection(adj_head)
      intersection |> set.size == size - 1
    })
  {
    True -> Ok([c0, ..cs])
    False -> Error(Nil)
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
