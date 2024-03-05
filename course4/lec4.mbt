let v2023: Int = (2023, 10, 24).0 // 2023
struct PersonalInfo { name: String; age: Int }
struct ContactInfo { name: String; telephone: Int }
struct AddressInfo { address: String; postal: Int }

let info: PersonalInfo = { name: "Moonbit", age: 1, }

struct A { val: Int; other: Int }
struct B { 
  val: Int // 可省略分号
  other: Int
}
let x = ( { val : 1, other: 10 } : A )
let x2 = ( { 
  val : 1,
  other: 10, // 注意逗号
} : A )

let old_info: PersonalInfo = { name: "Moonbit", age: 1, }
let a: Int = old_info.age // 1

let new_info: PersonalInfo = { .. old_info, age: 2, }
let other_info: PersonalInfo = { .. old_info, name: "Hello", }

fn f(info: PersonalInfo) -> (String, Int) { (info.name, info.age) }
fn g(pair: (String, Int)) -> PersonalInfo { { name: pair.0, age: pair.1, }}

fn accept_tuple(tuple: (Int, String)) -> Bool {
  true
}
let tuple_accepted: Bool = accept_tuple((1, "Yes"))

fn accept_a(a: A) -> Bool {
  true
}
// let not_accepted: Bool = accept_a(({ val : 1, other : 2 }: B)) // 不会编译
let a_accepted: Bool = accept_a(({other: 2, val: 1}: A))

fn head_opt(list: List[Int]) -> Option[Int] {
  match list {
    Nil => None
    Cons(head, tail) => Some(head)
  }
}

fn get_or_else(option_int: Option[Int], default: Int) -> Int {
  match option_int {
    None => default
    Some(value) => value
  }
}

fn is_zero(i: Int) -> Bool {
  match i {
    0 => true
    1 | 2 | 3 => false
    _ => false
  }
}

fn contains_zero(l: List[Int]) -> Bool {
  match l {
    Nil => false
    Cons(0, _) => true
    Cons(_, tl) => contains_zero(tl)
  }
}

fn first(pair: (Int, Int)) -> Int {
  match pair {
    (first, second) => first
  }
}

fn baby_name(info: PersonalInfo) -> Option[String] {
  match info {
    { age: 0, .. } => None
    { name, age } => Some(name)
  }
}

fn zip(l1: List[Int], l2: List[Char]) -> List[(Int ,Char)] {
  match (l1, l2) {
    _ => Nil // 顺序错误
    (Cons(hd, tl), Cons(hd2, tl2)) => Cons((hd, hd2), zip(tl, tl2))
    _ => Nil
  }
}

enum DaysOfWeek {
  Monday; Tuesday; Wednesday; Thursday; Friday; Saturday; Sunday
}

enum Coin {
  Head // 可省略分号
  Tail
}

let monday: DaysOfWeek = Monday
let tuesday: DaysOfWeek = Tuesday 

enum Repeat1 { A; B }
enum Repeat2 { A; B }
let repeat: Repeat1 = Repeat1::A  

enum ComputeResult {
    Success(Int)
    Overflow
    DivideByZero
}

struct PlusOne[T] { t: T; unit: Unit } // T * 1 = T，与（T，Unit)、T 同构

enum Nothing {}

enum PlusZero[T] { // T + 0 = T，与 T 同构
  CaseT(T)
  CaseZero(Nothing)
}
