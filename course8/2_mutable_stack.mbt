struct LinkedList[T] {
  mut head: Option[Node[T]]
  mut tail: Option[Node[T]]
} derive(Debug, Show)

struct Node[T] {
  value: T
  mut next: Option[Node[T]]
} derive(Debug, Show)

fn LinkedList::make[T]() -> LinkedList[T] {
  { head: None, tail: None }
}

fn push[T](self: LinkedList[T], value: T) -> LinkedList[T] {
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

fn peek[T](self: LinkedList[T]) -> Option[T] {
  match self.head {
    None => None
    Some(n) => Some(n.value)
  }
}

fn pop[T](self: LinkedList[T]) -> LinkedList[T] {
  match self.head {
    None => ()
    Some(n) => { match n.next {
      None => {
        self.head = None
        self.tail = None
      }
      Some(_) => {
        self.head = n.next
      }
    } }
  }
  self
}

fn length[T](self: LinkedList[T]) -> Int {
  // fn aux(node: Option[Node[T]]) -> Int {
  //   match node {
  //     None => 0
  //     Some(node) => 1 + aux(node.next)
  //   }
  // }
  // aux(self.head)
  fn aux2(node: Option[Node[T]], cumul) -> Int {
    match node {
      None => cumul
      Some(node) => aux2(node.next, 1 + cumul)
    }
  }
  aux2(self.head, 0)
}

test {
  let list = LinkedList::make()
  for i = 0; i < 100000; i = i + 1 {
    let _ = list.push(i)
  }
  @assertion.assert_eq(list.length(), 100000)?
}
