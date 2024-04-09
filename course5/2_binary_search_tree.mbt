enum IntTree {
  Empty
  Node(Int, IntTree, IntTree)
} derive (Debug, Show)

// Insert an element 插入元素
fn insert(tree: IntTree, value: Int) -> IntTree {
  match tree {
    Empty => Node(value, Empty, Empty)
    Node(v, left, right) => 
      if value == v { tree } else 
      if value < v { 
        let new_left = insert(left, value)
        Node(v, new_left, right)
      } else { Node(v, left, insert(right, value)) } 
  }
}

// Remove the largest element in the left tree 删除左子树最大元素
fn remove_largest(tree: IntTree) -> (IntTree, Int) {
  match tree {
    Empty => abort("Impossible")
    Node(v, left, Empty) => (left, v)
    Node(v, left, right) => {
      let (newRight, value) = remove_largest(right)
      (Node(v, left, newRight), value)
    }
  }
}

// Remove an element 删除元素
fn remove(tree: IntTree, value: Int) -> IntTree {
  match tree {
    Empty => Empty
    Node(root, left, right) => {
      if value < root { Node(root, remove(left, value), right) } else
      if value > root { Node(root, left, remove(right, value)) } else {
        match (left, right) {
          (Empty, Empty) => Empty
          (left, Empty) => left
          (Empty, right) => right
          (left, right) => {
            let (newLeft, newRoot) = remove_largest(left)
            Node(newRoot, newLeft, right)
          }
        }
      }
    }
  }
}

// Depth first search 深度优先遍历查找
fn dfs_search(target: Int, tree: IntTree) -> Bool {
  match tree {
    Empty => false
    Node(value, left, right) => value == target || 
        dfs_search(target, left) || 
        dfs_search(target, right)
  }
}

// Breadth first search 广度优先遍历查找
fn bfs_search(target: Int, queue: Queue[IntTree]) -> Bool {
  match peek(queue) {
    None => false
    Some(v) => match v {
      Empty => bfs_search(target, dequeue(queue))
      Node(value, left, right) => value == target || bfs_search(target, enqueue(enqueue(dequeue(queue), left), right))
    }
  }
}

// Depth first search and print all elements 深度优先遍历并输出
fn dfs_print(tree: IntTree) -> String {
  match tree {
    Empty => ""
    Node(value, left, right) => {
      let value_str = value.to_string()
      let left_str = dfs_print(left)
      let right_str = dfs_print(right)
      left_str + value_str + " " + right_str
    }
  }
}

// Breadth first search and print all elements 广度优先遍历并输出
fn bfs_print(queue: Queue[IntTree]) -> String {
  match peek(queue) {
    None => ""
    Some(v) => match v {
      Empty => bfs_print(dequeue(queue))
      Node(value, left, right) => value.to_string() + " " + bfs_print(enqueue(enqueue(dequeue(queue), left), right))
    }
  }
}

// Entrance to the main program 程序入口
fn init {
  let tree = [3, 2, 1, 0, 4, 5] |> stream |> fold_left(insert, IntTree::Empty)
  println("dfs_print: " + dfs_print(tree))
  println("bfs_print: " + bfs_print(from_list(Cons(tree, Nil))))
  let new_tree = remove(tree, 3)
  println("dfs_print: " + dfs_print(new_tree))
  println("bfs_print: " + bfs_print(enqueue(Queue::default(), new_tree)))
  let new_tree = remove(tree, 1)
  println("dfs_print: " + dfs_print(new_tree))
  println("bfs_print: " + bfs_print(enqueue(Queue::default(), new_tree)))
  if dfs_search(3, tree).not() { abort("") }
  if bfs_search(3, enqueue(from_list(Nil), tree)).not() { abort("") }
}

// ----- Utils 工具 -----
/// construct List from Array 从列表构建数组
fn stream[T](array: Array[T]) -> List[T] {
  fn go(idx: Int) -> List[T] {
    if idx == array.length() { Nil } else { Cons(array[idx], go(idx + 1)) }
  }

  go(0)
}

fn fold_left[A, B](list: List[A], f: (B, A) -> B, b: B) -> B {
  match list {
    Nil => b
    Cons(hd, tl) => fold_left(tl, f, f(b, hd))
  }
}

// ----- Queue 队列 -----

struct Queue[T] {
  front:List[T]
  back:List[T]
}

/// `Queue::default[T]()`
///
/// Create empty queue 创建空队列
fn Queue::default[T]() -> Queue[T] {
  { front: Nil, back: Nil }
}

/// `from_list[T](front: List[T])`
///
/// Create queue from list 从列表创建队列
fn from_list[T](front: List[T]) -> Queue[T] {
  { front:front, back:Nil }
}

/// `list_rev[T](xs: List[T])`
///
/// Reverse a list with tail recursion 基于尾递归的列表反转
fn list_rev[T](xs: List[T]) -> List[T] {
  fn go(acc, xs: List[T]) {
    match xs {
      Nil => acc
      Cons(x, rest) => go((Cons(x, acc) : List[T]), rest)
    }
  }

  go(Nil, xs)
}

/// `norm[T](q: Queue[T])`
///
/// Feed `back` into `front` so that `front` always have something 反转队列结构；确保列表头始终有元素
fn norm[T](q: Queue[T]) -> Queue[T] {
  match q {
    {front:Nil, back:b} => { front:list_rev(b), back:Nil }
    q => q
  }
}

/// `enqueue[T](q: Queue[T], x: T)`
///
/// Add an element to the end of the queue 向队尾添加一个元素
fn enqueue[T](q: Queue[T], x: T) -> Queue[T] {
  match q {
    {front:f, back:b} => norm({ front:f, back:Cons(x, b) })
  }
}

/// `peek[T](q: Queue[T])`
///
/// Remove the first element from the queue 取出队列中第一个元素
fn peek[T](q: Queue[T]) -> Option[T] {
  match q {
    {front:Nil, back:_} => None
    {front:Cons(x, _), back:_} => Some(x)
  }
}

/// `dequeue[T](q: Queue[T])`
///
/// The queue after an element is removed, returns itself if it's empty 取出一个元素后的队列；如果已经为空，则返回本身
fn dequeue[T](q: Queue[T]) -> Queue[T] {
  match q {
    {front:Nil, back:_} => q
    {front:Cons(_, f), back:b} => norm({ front:f, back:b })
  }
}
