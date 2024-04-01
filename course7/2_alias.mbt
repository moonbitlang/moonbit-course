struct Ref[T] { mut val : T }

fn init {
  let ref: Ref[Int] = { val: 1 } // ref is just a binding ref 本身只是一个数据绑定
  ref.val = 10 // the field of the struct can be modified 我们可以修改结构体的字段
  println(ref.val.to_string()) // output 10 输出 10
}

fn init {
  println("===============")
}

fn alter(a: Ref[Int], b: Ref[Int]) -> Unit {
  a.val = 10
  b.val = 20
}

fn init {
  let x: Ref[Int] = { val : 1 }
  alter(x, x)
  println(x.val.to_string()) // x.val will be updated twice x.val的值将会被改变两次
}