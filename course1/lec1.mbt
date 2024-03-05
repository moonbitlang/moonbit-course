fn num_water_bottles(num_bottles: Int, num_exchange: Int) -> Int {
  fn consume(num_bottles, num_drunk) {
    if num_bottles >= num_exchange {
      let num_bottles = num_bottles - num_exchange + 1
      let num_drunk = num_drunk + num_exchange
      consume(num_bottles, num_drunk)
    } else {
      num_bottles + num_drunk
    }
  }
  consume(num_bottles, 0)
}

fn init {
  assert(num_water_bottles(9, 3) == 13)
  assert(num_water_bottles(15, 4) == 19)
}

fn assert(test: Bool) {
  if test.not() {
    abort("Test failed")
  }
}
