///|
/// We define a type Map[Key, Value], which is actually List[(Key, Value)] inside
/// 我们定义一个类型Map，其实际值为List[(Key, Value)]
type Map[Key, Value] List[(Key, Value)]

// Create Map 创建表

///|
fn[Key, Value] Map::make() -> Map[Key, Value] {
  Map(Nil)
}

///|
/// Put a key-value pair or update the corresponding value 添加键值对，或更新键对应值
fn[Key, Value] put(
  map : Map[Key, Value],
  key : Key,
  value : Value
) -> Map[Key, Value] {
  let Map(original_map) = map
  Map(Cons((key, value), original_map))
}

///|
/// Get the value corresponding the given key 获取键对应值
fn[Key : Eq, Value] get(map : Map[Key, Value], key : Key) -> Value? {
  fn aux(list : List[(Key, Value)]) -> Value? {
    match list {
      Nil => None
      Cons((k, v), tl) =>
        if k == key { // Key implements Eq so == can be used Key 实现了 Eq 接口，因此可以利用 == 比较
          Some(v)
        } else {
          aux(tl)
        }
    }
  }

  aux(map.inner()) // Use .inner() to get the actual value 利用 .inner() 取出实际的值
}

///| map [ key ]
fn[Key : Eq, Value] Map::op_get(map : Map[Key, Value], key : Key) -> Value? {
  get(map, key)
}

///| map [ key ] = value
fn[Key : Eq, Value] Map::op_set(
  map : Map[Key, Value],
  key : Key,
  value : Value
) -> Map[Key, Value] {
  put(map, key, value)
}

///|
test {
  let empty : Map[Int, Int] = Map::make()
  let one = {
    empty[1] = 1
  } // Same as 等价于 let one = Map::op_set(empty, 1, 1)
  let _ = one[1]
  // Same as 等价于 let _ = Map::op_get(one, 1)
}

///|
enum List[T] {
  Nil
  Cons(T, List[T])
}
