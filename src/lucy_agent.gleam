import console.{read_line}
import gleam/int
import gleam/io
import scratch.{parse_age}

pub fn main() -> Nil {
  loop()
}

fn loop() {
  read_line("you> ")
  |> parse_age
  |> fn(result) {
    case result {
      Ok(age) -> io.println("echo: " <> int.to_string(age))
      Error(parse_error) -> 
        case parse_error {
          scratch.EmptyInput -> Nil
          scratch.NotANumber(message) -> io.println("error: " <> message)
          scratch.Negative(message) -> io.println("error: " <> message)
        }
    }
  }

  loop()
}
