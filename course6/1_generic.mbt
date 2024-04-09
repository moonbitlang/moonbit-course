test {
  let empty: Stack[Int] = Stack::empty()
  inspect(empty, ~content="Empty")?
  let one = empty.push(1)
  let two = one.push(1)
  let (top, rest) = two.pop()
  inspect(top, ~content="Some(1)")?
  @assertion.assert_eq(rest, one)?

  let empty_queue: Queue[Int] = Queue::empty()
  let one_queue = empty_queue.push(1)
  inspect(one_queue, ~content="{front: NonEmpty(1, Empty), back: Empty}")?
  let two_queue = one_queue.push(2)
  inspect(two_queue, ~content="{front: NonEmpty(1, Empty), back: NonEmpty(2, Empty)}")?
  let (first, rest) = two_queue.pop()
  inspect(first, ~content="Some(1)")?
  inspect(rest, ~content="{front: NonEmpty(2, Empty), back: Empty}")?
}

enum IntStack {
  Empty
  NonEmpty(Int, IntStack)
} derive(Debug, Show, Eq)
fn IntStack::empty() -> IntStack { Empty }
fn push(self: IntStack, value: Int) -> IntStack { NonEmpty(value, self) }
fn pop(self: IntStack) -> (Option[Int], IntStack) {
  match self {
    Empty => (None, Empty)
    NonEmpty(top, rest) => (Some(top), rest)
  }
}

enum StringStack {
  Empty
  NonEmpty(String, StringStack)
} derive(Debug, Show, Eq)
fn StringStack::empty() -> StringStack { Empty }
fn push(self: StringStack, value: String) -> StringStack { NonEmpty(value, self) }
fn pop(self: StringStack) -> (Option[String], StringStack) {
  match self {
    Empty => (None, Empty)
    NonEmpty(top, rest) => (Some(top), rest)
  }
}

enum Stack[T] {
  Empty
  NonEmpty(T, Stack[T])
} derive(Debug, Show, Eq)
fn Stack::empty[T]() -> Stack[T] { Empty }
fn push[T](self: Stack[T], value: T) -> Stack[T] { NonEmpty(value, self) }
fn pop[T](self: Stack[T]) -> (Option[T], Stack[T]) {
  match self {
    Empty => (None, Empty)
    NonEmpty(top, rest) => (Some(top), rest)
  }
}

struct Queue[T] {
  front: Stack[T]
  back: Stack[T]
} derive(Debug, Show, Eq)
fn Queue::empty[T]() -> Queue[T] { {front: Empty, back: Empty} }
fn push[T](self: Queue[T], value: T) -> Queue[T] { // push element to the end of the queue 将元素存入队尾
  normalize({ ..self, back: self.back.push(value)})
}
fn pop[T](self: Queue[T]) -> (Option[T], Queue[T]) { // remove the first element 取出第一个元素
  match self.front {
    Empty => (None, self)
    NonEmpty(top, rest) => (Some(top), normalize({ ..self, front: rest}))
  }
}
fn normalize[T](self: Queue[T]) -> Queue[T] { // if front is empty, revert back into front 如果front为空，反转back到front
  match self.front {
    Empty => { front: self.back.reverse(), back: Empty }
    _ => self
  }
}
fn reverse[T](self: Stack[T]) -> Stack[T] { // aux: reverse stack 辅助函数：反转堆栈
  fn go(acc, xs: Stack[T]) {
    match xs {
      Empty => acc
      NonEmpty(top, rest) => go((NonEmpty(top, acc) : Stack[T]), rest)
    }
  }

  go(Empty, self)
}
