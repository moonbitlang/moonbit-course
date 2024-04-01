fn square(x: Int) -> Int {x * x}
fn init {
  let x = {
    println("hello moonbit")
    1 + 1
  }
  let z: Int = square(x)
}

fn init {
  println("==============")
}

fn init {
  let z: Int = {
    println("hello moonbit")
    1 + 1
  } * {
    println("hello moonbit")
    1 + 1
  }
}
