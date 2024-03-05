fn init {
  let mut i = 0
  while i < 2, i = i + 1 {
    println("Output")
  } // 重复输出2次
  println("======")
  fn loop_(i : Int) {
    if i < 2 {
      println("Hello!")
      loop_(i + 1)
    } else {
      ()
    }
  }
  loop_(0) // 重复输出2次
  println("======")
  fn print_first_3() {
    let mut i = 0
    while i < 10, i = i + 1 {
      if i == 3 {
        break // 跳过从3开始的情况
      } else {
        println(i.to_string())
      }
    }
  }
  print_first_3()
  println("======")
  fn print_skip_3() {
    let mut i = 0
    while i < 10, i = i + 1 {
      if i == 3 {
        continue // 跳过3
      } else { () }
      println(i.to_string())
    }
  }
  print_skip_3()
  println("======")
  fn fib_mut(n: Int) -> Int { // 对于相同输入，总是有相同输出
    let mut acc1 = 0; let mut acc2 = 1; let mut i = 0
    while i < n, i = i + 1 {
      let t = acc1 + acc2
      acc1 = acc2;  acc2 = t
    }
    acc1
  }
  println(fib_mut(10))
}
