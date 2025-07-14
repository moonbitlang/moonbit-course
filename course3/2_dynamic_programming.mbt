///|
typealias @immut/hashmap.T as Map

///|
fnalias @immut/hashmap.T::(get, add as put)

///|
fnalias @immut/hashmap.new as make

///|
fnalias Option::unwrap_or as get_or_else

///|
/// Top-down 自顶向下
/// Fibonacci using map 利用表计算斐波那契数列
fn fib1(num : Int) -> Int64 {
  fn aux(num : Int, map : Map[Int, Int64]) -> (Int64, Map[Int, Int64]) {
    match get(map, num) {
      Some(result) => (result, map)
      None => {
        let (result_1, map_1) = aux(num - 1, map)
        let (result_2, map_2) = aux(num - 2, map_1)
        (result_1 + result_2, put(map_2, num, result_1 + result_2))
      }
    }
  }

  let map = put(put(make(), 1, 1L), 2, 1L)
  aux(num, map).0
}

///|
/// Use mutable variable to avoid passing map around
/// 利用变量避免传递map
fn fib1_mut(num : Int) -> Int64 {
  let mut map = put(put(make(), 1, 1L), 2, 1L)
  fn aux(num : Int) -> Int64 {
    match get(map, num) {
      Some(result) => result
      None => {
        let result_1 = aux(num - 1)
        let result_2 = aux(num - 2)
        map = put(map, num, result_1 + result_2)
        result_1 + result_2
      }
    }
  }

  aux(num)
}

///|
/// Bottom-up 自底向上
fn fib2(num : Int) -> Int64 {
  fn aux(n : Int, map : Map[Int, Int64]) -> Int64 {
    let result = get_or_else(get(map, n - 1), 1L) +
      get_or_else(get(map, n - 2), 1L)
    if n == num {
      result
    } else {
      aux(n + 1, put(map, n, result))
    }
  }

  let map = put(put(make(), 0, 0L), 1, 1L)
  aux(1, map)
}

///|
test {
  assert_eq(fib1(60), 1548008755920L)
  assert_eq(fib1_mut(60), 1548008755920L)
  assert_eq(fib2(60), 1548008755920L)
}
