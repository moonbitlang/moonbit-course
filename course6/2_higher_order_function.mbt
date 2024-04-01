fn fold_right[A, B](list : List[A], 
  f : (A, B) -> B, b : B) -> B {
  match list {
    Nil => b
    Cons(hd, tl) => f(hd, fold_right(tl, f, b))
  }
}

fn map[A, B](list: List[A], f: (A) -> B) -> List[B] {
  match list {
    Nil => Nil
    Cons(hd, tl) => Cons(f(hd), map(tl, f))
  }
}

fn map_with_fold_right[A, B](list : List[A], f : (A) -> B) -> List[B] {
  fold_right(list, fn(value, cumulator) { Cons(f(value), cumulator) }, Nil)
}

fn fold_left[A, B](list : List[A], f : (B, A) -> B, b : B) -> B {
  match list {
    Nil => b
    Cons(hd, tl) => fold_left(tl, f, f(b, hd))
  }
}

/// convert list to string 将列表转化为字符串
fn to_string[T : Show](self : List[T]) -> String {
  fn go(ls : List[T]){
    match ls {
      Nil => ""
      Cons(x,Nil) => "\(x)"
      Cons(x,xs) => "\(x), " + go(xs)
    }
  }
  "[" + go(self) + "]"
}

enum List[T] {
  Nil
  Cons(T, List[T])
}

fn init {
  println(fold_left(Cons("1", Cons("2", Cons("3", Nil))), fn (b: String, a) { "(\(b) + \(a))" }, "0"))
  println(fold_right(Cons("1", Cons("2", Cons("3", Nil))), fn (a: String, b: String) { "(\(a) + \(b))" }, "0"))
  println(map(Cons(0, Cons(1, Cons(2, Cons(3, Nil)))), fn (i) { i * 10 }))
}