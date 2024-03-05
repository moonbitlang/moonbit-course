struct Queue[T] {
  array: Array[T]
  start: Int
  end: Int
  length: Int
}

fn make[T: Default]() -> Queue[T] { // 类型参数T应当满足Default接口
  { 
    array: Array::make(5, T::default()), // 我们可以利用接口中的方法，返回类型为Self，即T
    start: 0, end: 0, length: 0 
  } 
}

struct BoxedInt { value : Int } derive(Compare, Debug) // 派生内建接口

fn BoxedInt::default() -> BoxedInt { // 定义方法即实现Default接口
  { value : Int::default() } // 使用整数的默认值 0
}

fn init {
  let array: Queue[BoxedInt] = make()
}

fn BoxedInt::plus_one(b: BoxedInt) -> BoxedInt {
  { value : b.value + 1 }
}
fn plus_two(self: BoxedInt) -> BoxedInt { // 参数名称为self时可省略 <类型>::
  { value : self.value + 2}
}

fn init {
  let _five = { value: 1 }.plus_one().plus_one().plus_two()
  // 无需进行深层嵌套，方便理解
  let _five = plus_two(plus_one(plus_one({value: 1})))
}

// 同时定义比较运算符、实现Eq接口
fn BoxedInt::op_equal(i: BoxedInt, j: BoxedInt) -> Bool {
  i.value == j.value
}

// 定义加法运算符
fn BoxedInt::op_add(i: BoxedInt, j: BoxedInt) -> BoxedInt {
  { value: i.value + j.value }
}

fn init {
  let _ = { value: 10 } == { value: 100 } // false
  let _ = { value: 10 } + { value: 100 } // { value: 110 }
}
