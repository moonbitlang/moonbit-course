///|
test {
  let x = Queue::new()
  x.push(1)
  x.push(2)
  x.push(3)
  x.push(4)
  x.push(5)
  inspect(x.pop(), content="Some(1)")
  inspect(x.pop(), content="Some(2)")
  inspect(x.length(), content="3")
  inspect(x.pop(), content="Some(3)")
  inspect(x.peek(), content="Some(4)")
  inspect(x.pop(), content="Some(5)")
  inspect(x.pop(), content="None")
  inspect(x.peek(), content="None")
  inspect(x.length(), content="0")
}

///|
test {
  let x = Queue::new()
  for i = 0; i < 7; i = i + 1 {
    x.push(i)
  }
  x.pop() |> ignore
  x.pop() |> ignore
  for i = 8; i < 15; i = i + 1 {
    x.push(i)
  }
  inspect(x.peek(), content="Some(2)")
}

///|
struct Queue[T] {
  mut array : FixedArray[T]
  mut start : Int
  mut end : Int // end指向队尾的空格子
  mut length : Int
}

///|
fn[T : Default] Queue::new() -> Queue[T] {
  { array: FixedArray::make(8, T::default()), start: 0, end: 0, length: 0 }
}

///|
fn[T : Default] Queue::push(self : Queue[T], val : T) -> Unit {
  if self.length == self.array.length() {
    let new_array = FixedArray::make(self.length * 2, T::default())
    for i = 0; i < self.array.length(); i = i + 1 {
      new_array.set(i, self.array[(self.start + i) % self.array.length()])
    }
    self.start = 0
    self.end = self.array.length()
    self.array = new_array
  }
  self.array.set(self.end, val)
  self.end = (self.end + 1) % self.array.length()
  self.length = self.length + 1
}

///|
fn[T] Queue::length(self : Queue[T]) -> Int {
  self.length
}

///|
fn[T : Default] Queue::pop(self : Queue[T]) -> T? {
  let val = self.peek()
  if val is Some(_) {
    self.array[self.start] = T::default()
    self.start = (self.start + 1) % self.array.length()
    self.length = self.length - 1
  }
  val
}

///|
fn[T] Queue::peek(self : Queue[T]) -> T? {
  if self.start == self.end {
    None
  } else {
    self.array.get(self.start)
  }
}
