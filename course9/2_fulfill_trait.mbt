///|
struct Queue[T] {
  array : Array[T]
  start : Int
  end : Int
  length : Int
}

///|
/// T : Default -> T should fulfill the trait Default
/// T : Default -> 类型参数T应当满足Default接口
fn[T : Default] Queue::make() -> Queue[T] {
  {
    array: Array::make(5, T::default()), // default can be used and returns Self (T) 我们可以利用接口中的方法，返回类型为Self，即T
    start: 0,
    end: 0,
    length: 0,
  }
}

///|
struct BoxedInt {
  value : Int
} derive(Compare, Show) // derive builtin traits 派生内建接口

///|
impl Default for BoxedInt with default() -> BoxedInt {
  { value: Int::default() } // using the default of Int 0 使用整数的默认值 0
}

///|
test {
  let array : Queue[BoxedInt] = Queue::make()
  inspect(
    array.array,
    content="[{value: 0}, {value: 0}, {value: 0}, {value: 0}, {value: 0}]",
  )
}

///|
fn BoxedInt::plus_one(self : BoxedInt) -> BoxedInt {
  { value: self.value + 1 }
}

///|
fn BoxedInt::plus_two(self : BoxedInt) -> BoxedInt {
  { value: self.value + 2 }
}

///|
fn init {
  let _five = { value: 1 }.plus_one().plus_one().plus_two()
  // uniform function call can be easier to understand
  // 无需进行深层嵌套，方便理解
  let _five = { value: 1 }
    |> BoxedInt::plus_one()
    |> BoxedInt::plus_one()
    |> BoxedInt::plus_two()

}

///|
/// defining == operator / implementing trait Eq
/// 同时定义比较运算符、实现Eq接口
impl Eq for BoxedInt with op_equal(i : BoxedInt, j : BoxedInt) -> Bool {
  i.value == j.value
}

///|
/// defining + operator
/// 定义加法运算符
impl Add for BoxedInt with op_add(i : BoxedInt, j : BoxedInt) -> BoxedInt {
  { value: i.value + j.value }
}

///|
test {
  inspect({ value: 10 } == { value: 100 }, content="false")
  inspect({ value: 10 } + { value: 100 }, content="{value: 110}")
}
