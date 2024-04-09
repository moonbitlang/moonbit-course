fn square(x: Int) -> Int {x * x}
test {
  let buffer = Buffer::make(20)
  fn println(x: String) {
    buffer.write_string(x)
    buffer.write_string("\n")
  }

  let x = {
    println("hello moonbit")
    1 + 1
  }
  let z: Int = square(x)

  @assertion.assert_eq(z, 4)?
  buffer.expect(~content=
    #|hello moonbit
    #|
  )?
}

test {
  let buffer = Buffer::make(20)
  fn println(x: String) {
    buffer.write_string(x)
    buffer.write_string("\n")
  }

  let z: Int = {
    println("hello moonbit")
    1 + 1
  } * {
    println("hello moonbit")
    1 + 1
  }
  
  @assertion.assert_eq(z, 4)?
  buffer.expect(~content=
    #|hello moonbit
    #|hello moonbit
    #|
  )?
}
