struct Queue {
  mut array: Array[Int]
  mut start: Int
  mut end: Int
  mut length: Int
} derive (Show)

fn make() -> Queue {
  {
    array: Array::make(5, 0),
    start: 0,
    end: 0,
    length: 0
  }
}

fn push(self: Queue, t: Int) -> Queue {
  if self.length == self.array.length() {
    let new_array = Array::make(self.array.length() * 2, 0)
    let mut i = 0
    while i < self.array.length(), i = i + 1 {
      new_array[i] = self.array[(self.start + i) % self.array.length()]
    }
    self.start = 0
    self.end = self.array.length()
    self.array = new_array
    self.push(t)
    self
  } else {
    self.array[self.end] = t
    self.end = (self.end + 1) % self.array.length()
    self.length = self.length + 1
    self   
  }
}

fn peek(self: Queue) -> Option[Int] {
  if self.end == self.start { None } else { Some(self.array[self.start]) }
}

fn pop(self: Queue) -> Queue {
  self.start = (self.start + 1) % self.array.length()
  self.length = self.length - 1
  self
}

fn length(self: Queue) -> Int {
  self.length
}

fn display(self: Queue) {
  let mut i = 0
  while i < self.length, i = i + 1 {
    print(self.array[(self.start + i) % self.array.length()].to_string() + " ")
  }
  println("")
}

fn init {
  let queue = make()

  queue.push(1).push(5).push(10).pop().pop().pop().push(100).push(1000).push(6).push(7).push(8).push(10)
  println(queue.length())
  queue.display()
}