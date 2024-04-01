// Self stands for the type that implements the trait
// Self代表实现该接口的类型

// These two traits are builtin 下方两个接口是内置接口
// trait Compare {
//   compare(Self, Self) -> Int 
// }

// trait Default {
//   default() -> Self
// }

enum Tree[T] {
  Empty
  Node(T, Tree[T], Tree[T])
}

// T : Compare -> T should fulfill the trait Compare
// T : Compare -> 类型参数T应当满足比较接口
fn insert[T : Compare](tree : Tree[T], value : T) -> Tree[T] {
  
  match tree {
    Empty => Node(value, Empty, Empty) 
    Node(v, left, right) =>  
      if T::compare(value, v) == 0 { // compare can be used 可以使用比较方法
        tree
      } else if T::compare(value, v) < 0 { // compare can be used 可以使用比较方法
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

// T : Default -> T should fulfill the trait Default
// T : Default -> 类型参数T应当满足Default接口
fn Queue::make[T: Default]() -> Queue[T] { 
  { 
    array: Array::make(5, T::default()), // default can be used and returns Self (T) 我们可以利用接口中的方法，返回类型为Self，即T
    start: 0, end: 0, length: 0 
  } 
}