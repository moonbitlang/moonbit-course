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

test {
  @assertion.assert_eq(
    fold_left(List::["1", "2", "3"], fn(b : String, a) { "(\(b) + \(a))" }, "0"),
    "(((0 + 1) + 2) + 3)",
  )?
  @assertion.assert_eq(
    fold_right(
      List::["1", "2", "3"],
      fn(a : String, b : String) { "(\(a) + \(b))" },
      "0",
    ),
    "(1 + (2 + (3 + 0)))",
  )?
  @assertion.assert_eq(
    map(List::[0, 1, 2, 3, 4], fn(i) { i * 10 }),
    List::[0, 10, 20, 30, 40],
  )?
}
