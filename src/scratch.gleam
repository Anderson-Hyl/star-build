import gleam/int
import gleam/result
import gleam/string

pub type ParseError {
  EmptyInput
  NotANumber(message: String)
  Negative(message: String)
}

pub fn parse_age(input: String) -> Result(Int, ParseError) {
  let trim_input = string.trim(input)
  case trim_input {
    "" -> Error(EmptyInput)
    valid_trim_input -> 
      int.parse(valid_trim_input)
      |> result.replace_error(NotANumber(message: "not a number " <> input))
      |> result.try(fn(age) {
        case age >= 0 {
          True -> Ok(age)
          False -> Error(NotANumber(message: "Age can not be negative"))
        }
      })
  }
}
