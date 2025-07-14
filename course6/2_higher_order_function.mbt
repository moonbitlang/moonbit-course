///|
fn[A, B] fold_right(list : List[A], f : (A, B) -> B, b : B) -> B {
  match list {
    Nil => b
    Cons(hd, tl) => f(hd, fold_right(tl, f, b))
  }
}

///|
fn[A, B] map(list : List[A], f : (A) -> B) -> List[B] {
  match list {
    Nil => Nil
    Cons(hd, tl) => Cons(f(hd), map(tl, f))
  }
}

///|
fn[A, B] map_with_fold_right(list : List[A], f : (A) -> B) -> List[B] {
  fold_right(list, fn(value, cumulator) { Cons(f(value), cumulator) }, Nil)
}

///|
fn[A, B] fold_left(list : List[A], f : (B, A) -> B, b : B) -> B {
  match list {
    Nil => b
    Cons(hd, tl) => fold_left(tl, f, f(b, hd))
  }
}

///|
test {
  assert_eq(
    fold_left(
      ["1", "2", "3"].to_list(),
      fn(b : String, a) { "(\{b} + \{a})" },
      "0",
    ),
    "(((0 + 1) + 2) + 3)",
  )
  assert_eq(
    fold_right(
      ["1", "2", "3"].to_list(),
      fn(a : String, b : String) { "(\{a} + \{b})" },
      "0",
    ),
    "(1 + (2 + (3 + 0)))",
  )
  assert_eq(
    map([0, 1, 2, 3, 4].to_list(), fn(i) { i * 10 }),
    [0, 10, 20, 30, 40].to_list(),
  )
}

///|
fn[T] Array::to_list(array : Array[T]) -> List[T] {
  fn go(idx : Int) -> List[T] {
    if idx == array.length() {
      Nil
    } else {
      Cons(array[idx], go(idx + 1))
    }
  }

  go(0)
}

///|
enum List[T] {
  Nil
  Cons(T, List[T])
} derive(Eq, Show)
