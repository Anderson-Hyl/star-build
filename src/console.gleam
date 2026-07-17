@external(erlang, "io", "get_line")
fn erl_get_line(prompt: String) -> String

pub fn read_line(prompt: String) -> String {
  erl_get_line(prompt)
}
