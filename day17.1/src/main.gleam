import gleam/erlang
import gleam/float
import gleam/int
import gleam/io

import gleam/list

import gleam/string

type Film(value) {
  Film(prev: List(value), current: value, next: List(value))
}

fn film_next(film: Film(value)) {
  let Film(prev, current, next) = film
  case next {
    [] -> {
      film
    }
    [v, ..rest] -> {
      Film([current, ..prev], v, rest)
    }
  }
}

fn film_prev(film: Film(value)) {
  let Film(prev, current, next) = film
  case prev {
    [] -> {
      film
    }
    [v, ..rest] -> {
      Film(rest, v, [current, ..next])
    }
  }
}

fn film_ff(film: Film(value), frames: Int) {
  case frames {
    0 -> film
    _ ->
      list.range(0, frames - 1)
      |> list.fold(film, fn(film, _) { film_next(film) })
  }
}

fn film_rw(film: Film(value), frames: Int) {
  list.range(0, frames - 1) |> list.fold(film, fn(film, _) { film_prev(film) })
}

fn film_start(film: Film(value)) {
  film |> film_rw(film.prev |> list.length)
}

type Computer {
  Computer(
    reg_a: Int,
    reg_b: Int,
    reg_c: Int,
    program: Film(Int),
    output: List(Int),
  )
}

fn step(computer: Computer) {
  Computer(..computer, program: computer.program |> film_next)
}

pub fn main() {
  let assert [reg_a_raw, reg_b_raw, reg_c_raw, _, program_raw] = lines()

  let reg_a = parse_register(reg_a_raw)
  let reg_b = parse_register(reg_b_raw)
  let reg_c = parse_register(reg_c_raw)

  let assert [first, ..rest] = parse_program(program_raw)

  let computer = Computer(reg_a, reg_b, reg_c, Film([], first, rest), [])

  let output = run(computer)

  let result =
    output
    |> list.map(fn(v) { v |> int.to_string })
    |> string.join(",")

  io.println(result)
}

fn run(computer: Computer) {
  let instruction = get_instruction(computer.program.current)
  let computer = step(computer)
  let operand = computer.program.current
  let computer = step(computer)

  let computer = instruction(computer, operand)

  case computer.program.next {
    [] -> {
      computer.output |> list.reverse
    }
    _ -> {
      run(computer)
    }
  }
}

fn get_value(computer: Computer, operand: Int) {
  case operand {
    0 -> 0
    1 -> 1
    2 -> 2
    3 -> 3
    4 -> computer.reg_a
    5 -> computer.reg_b
    6 -> computer.reg_c
    _ -> panic as { "Invalid operand: " <> operand |> int.to_string }
  }
}

fn adv(computer: Computer, operand: Int) {
  let value = get_value(computer, operand)
  Computer(..computer, reg_a: xdv(computer.reg_a, value))
}

fn bxl(computer: Computer, operand: Int) {
  let updated_reg_b = computer.reg_b |> int.bitwise_exclusive_or(operand)
  Computer(..computer, reg_b: updated_reg_b)
}

fn bst(computer: Computer, operand: Int) {
  let value = get_value(computer, operand)
  let updated_reg_b = value % 8
  Computer(..computer, reg_b: updated_reg_b)
}

fn jnz(computer: Computer, operand: Int) {
  case computer.reg_a {
    0 -> computer
    _ -> {
      let start = computer.program |> film_start
      let jumped = start |> film_ff(operand)
      Computer(..computer, program: jumped)
    }
  }
}

fn bxc(computer: Computer, _: Int) {
  let updated_reg_b = computer.reg_b |> int.bitwise_exclusive_or(computer.reg_c)
  Computer(..computer, reg_b: updated_reg_b)
}

fn out(computer: Computer, operand: Int) {
  let value = get_value(computer, operand)
  let output = value % 8
  Computer(..computer, output: [output, ..computer.output])
}

fn bdv(computer: Computer, operand: Int) {
  let value = get_value(computer, operand)
  Computer(..computer, reg_b: xdv(computer.reg_a, value))
}

fn cdv(computer: Computer, operand: Int) {
  let value = get_value(computer, operand)
  Computer(..computer, reg_c: xdv(computer.reg_a, value))
}

fn xdv(reg_a: Int, value: Int) {
  case value >= { log2(reg_a) + 1 } {
    True -> 0
    False -> {
      let assert Ok(denominator) = float.power(2.0, { value |> int.to_float })

      let result = int.to_float(reg_a) /. denominator
      result |> float.truncate
    }
  }
}

fn log2(n: Int) -> Int {
  case n {
    0 -> panic as "Cannot take log2 of 0"
    1 -> 0
    _ -> {
      // Efficient bit shifting implementation
      let #(n1, log1) = case n >= int.bitwise_shift_left(1, 16) {
        True -> #(int.bitwise_shift_right(n, 16), 16)
        False -> #(n, 0)
      }
      let #(n2, log2) = case n1 >= int.bitwise_shift_left(1, 8) {
        True -> #(int.bitwise_shift_right(n1, 8), 8)
        False -> #(n1, 0)
      }
      let #(n3, log3) = case n2 >= int.bitwise_shift_left(1, 4) {
        True -> #(int.bitwise_shift_right(n2, 4), 4)
        False -> #(n2, 0)
      }
      let #(n4, log4) = case n3 >= int.bitwise_shift_left(1, 2) {
        True -> #(int.bitwise_shift_right(n3, 2), 2)
        False -> #(n3, 0)
      }
      let log5 = case n4 >= int.bitwise_shift_left(1, 1) {
        True -> 1
        False -> 0
      }
      log1 + log2 + log3 + log4 + log5
    }
  }
}

fn get_instruction(i: Int) {
  case i {
    0 -> adv
    1 -> bxl
    2 -> bst
    3 -> jnz
    4 -> bxc
    5 -> out
    6 -> bdv
    7 -> cdv
    _ -> {
      panic as { "Invalid instruction: " <> i |> int.to_string }
    }
  }
}

fn parse_register(raw: String) {
  let assert [_, _, value] = string.split(raw, " ")
  let assert Ok(value) = int.parse(value)
  value
}

fn parse_program(raw: String) {
  let assert [_, value] = string.split(raw, " ")
  let value =
    value
    |> string.split(",")
    |> list.map(fn(v) {
      let assert Ok(v) = int.parse(v)
      v
    })
  value
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
