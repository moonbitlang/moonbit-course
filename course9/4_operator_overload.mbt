///|
struct BoxedInt {
  value : Int
} derive(Show)

///|
impl Eq for BoxedInt with equal(i : BoxedInt, j : BoxedInt) -> Bool {
  i.value == j.value
}

///|
impl Add for BoxedInt with add(i : BoxedInt, j : BoxedInt) -> BoxedInt {
  { value: i.value + j.value }
}
