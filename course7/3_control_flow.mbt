fn init {
  let mut i = 0
  while i < 2 {
    i = i + 1
    println("Output")
  } // print twice 重复输出2次
  println("======")
  fn loop_(i : Int) {
    if i < 2 {
      println("Hello!")
      loop_(i + 1)
    } else {
      ()
    }
  }
  loop_(0) // print twice 重复输出2次
  println("======")
  fn print_first_3() {
    let mut i = 0
    while i < 10 {
      if i == 3 {
        break // skip all cases larger than 3 跳过从3开始的情况
      } else {
        println(i.to_string())
      }
      i = i + 1
    }
  }
  print_first_3()
  println("======")
  fn print_skip_3() {
    let mut i = 0
    while i < 10 {
      if i == 3 {
        continue // skip 3 跳过 3
      } else { () }
      println(i.to_string())
      i = i + 1
    }
  }
  print_skip_3()
  println("======")
  fn fib_mut(n: Int) -> Int { // same output for the same input 对于相同输入，总是有相同输出
    let mut acc1 = 0; let mut acc2 = 1; let mut i = 0
    while i < n {
      let t = acc1 + acc2
      acc1 = acc2; acc2 = t
      i = i + 1
    }
    acc1
  }
  println(fib_mut(10))
}
