///|
struct LinkedList[T] {
  mut head : Node[T]?
  mut tail : Node[T]?
} derive(Show)

///|
struct Node[T] {
  value : T
  mut next : Node[T]?
} derive(Show)

///|
fn[T] LinkedList::make() -> LinkedList[T] {
  { head: None, tail: None }
}

///|
fn[T] push(self : LinkedList[T], value : T) -> LinkedList[T] {
  let node = { value, next: None }
  match self.tail {
    None => {
      self.head = Some(node)
      self.tail = Some(node)
    }
    Some(n) => {
      n.next = Some(node)
      self.tail = Some(node)
    }
  }
  self
}

///|
fn[T] peek(self : LinkedList[T]) -> T? {
  match self.head {
    None => None
    Some(n) => Some(n.value)
  }
}

///|
fn[T] pop(self : LinkedList[T]) -> LinkedList[T] {
  match self.head {
    None => ()
    Some(n) =>
      match n.next {
        None => {
          self.head = None
          self.tail = None
        }
        Some(_) => self.head = n.next
      }
  }
  self
}

///|
fn[T] length(self : LinkedList[T]) -> Int {
  // fn aux(node: Option[Node[T]]) -> Int {
  //   match node {
  //     None => 0
  //     Some(node) => 1 + aux(node.next)
  //   }
  // }
  // aux(self.head)
  fn aux2(node : Node[T]?, cumul) -> Int {
    match node {
      None => cumul
      Some(node) => aux2(node.next, 1 + cumul)
    }
  }

  aux2(self.head, 0)
}

///|
test {
  let list = LinkedList::make()
  for i = 0; i < 100000; i = i + 1 {
    let _ = list.push(i)

  }
  assert_eq(list.length(), 100000)
}
