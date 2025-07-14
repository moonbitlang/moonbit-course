///|
fn square(x : Int) -> Int {
  x * x
}

///|
test {
  let buffer = StringBuilder::new()
  fn println(x : String) {
    buffer.write_string(x)
    buffer.write_string("\n")
  }

  let x = {
    println("hello moonbit")
    1 + 1
  }
  let z : Int = square(x)
  assert_eq(z, 4)
  inspect(
    buffer,
    content=(
      #|hello moonbit
      #|
    ),
  )
}

///|
test {
  let buffer = StringBuilder::new()
  fn println(x : String) {
    buffer.write_string(x)
    buffer.write_string("\n")
  }

  let z : Int = {
      println("hello moonbit")
      1 + 1
    } *
    {
      println("hello moonbit")
      1 + 1
    }
  assert_eq(z, 4)
  inspect(
    buffer,
    content=(
      #|hello moonbit
      #|hello moonbit
      #|
    ),
  )
}
