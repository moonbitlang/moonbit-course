trait Compare {
  compare(Self, Self) -> Int // Self代表实现该接口的类型
}
trait Default {
  default() -> Self
}

enum Tree[T] {
  Empty
  Node(T, Tree[T], Tree[T])
}

fn insert[T : Compare](tree : Tree[T], value : T) -> Tree[T] {
  // 类型参数T应当满足比较接口
  match tree {
    Empty => Node(value, Empty, Empty) 
    Node(v, left, right) =>  
      if T::compare(value, v) == 0 { // 可以使用比较方法
        tree
      } else if T::compare(value, v) < 0 { // 可以使用比较方法
        Node(v, insert(left, value), right)
      } else {
        Node(v, left, insert(right, value))
      }
  }
}

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
