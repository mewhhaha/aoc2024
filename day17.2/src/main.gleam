import gleam/erlang
import gleam/float
import gleam/int
import gleam/io
import gleam/option

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

  let assert [first, ..back] = parse_program(program_raw)

  let computer = Computer(reg_a, reg_b, reg_c, Film([], first, back), [])

  let assert option.Some(result) =
    run_until_replicating(15, 1, computer, [first, ..back])

  io.println(result |> int.to_string)
}

// Done through reading through all the instructions and realizing that
// 1. reg_a is divided by 8 (2^3) by the end of each iteration
// 2. reg_b is modulo 8 by the start of each iteration
// 3. reg_c is derived from reg_a and reg_b
// 4. Since reg_a is truncated after division there are 7 for reg_a
// 5. The reg_a for the last iteration must be 0-7 since it needs to be truncated and exit
//
// So
// reg_b is 0-7
// reg_a is whatever solved the previous iteration * 8
// 
// Since we can guess the beginning state of the last iteration
// and then guess the beginning state of the previous iteration 
fn run_until_replicating(
  n: Int,
  input: Int,
  computer: Computer,
  output: List(Int),
) {
  let current = output |> list.drop(n)

  let offset_input = list.range(0, 7) |> list.map(fn(i) { i + input })
  let valid_inputs = {
    use a <- fn(f) { offset_input |> list.filter(f) }
    use b <- fn(f) { list.range(0, 7) |> list.any(f) }

    let c = Computer(..computer, reg_a: a, reg_b: b)
    let result = run(c)
    case result == current {
      True -> True
      False -> False
    }
  }

  case n {
    0 -> {
      valid_inputs
      |> list.find(fn(v) {
        let computer = Computer(..computer, reg_a: v)
        let result = run(computer)
        output == result
      })
      |> option.from_result
    }

    _ -> {
      valid_inputs
      |> list.fold(option.None, fn(acc, input) {
        case acc {
          option.Some(_) -> acc
          option.None ->
            run_until_replicating(n - 1, input * 8, computer, output)
        }
      })
    }
  }
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
  let l2 = case reg_a {
    0 -> 0
    _ -> log2(reg_a) + 1
  }
  case value >= l2 {
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
