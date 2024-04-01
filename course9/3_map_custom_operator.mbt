// We define a type Map[Key, Value], which is actually List[(Key, Value)] inside
// 我们定义一个类型Map，其实际值为List[(Key, Value)]
type Map[Key, Value] List[(Key, Value)]

// Create Map 创建表
fn Map::make[Key, Value]() -> Map[Key, Value] { 
  Map(Nil)
}

// Put a key-value pair or update the corresponding value 添加键值对，或更新键对应值
fn put[Key, Value](map: Map[Key, Value], key: Key, value: Value) -> Map[Key, Value] { 
  let Map(original_map) = map
  Map( Cons( (key, value), original_map ) )
}

// Get the value corresponding the given key 获取键对应值
fn get[Key: Eq, Value](map : Map[Key, Value], key : Key) -> Option[Value] {
  fn aux(list : List[(Key, Value)]) -> Option[Value] {
    match list {
      Nil => None
      Cons((k, v), tl) => if k == key { // Key implements Eq so == can be used Key实现了Eq接口，因此可以利用==比较
        Some(v)
      } else {
        aux(tl)
      }
    }
  }

  aux(map.0) // Use .0 to get the actual value 利用 .0 取出实际的值
}

// map [ key ]
fn Map::op_get[Key: Eq, Value](map: Map[Key, Value], key: Key) -> Option[Value] {
  get(map, key)
}
// map [ key ] = value
fn Map::op_set[Key: Eq, Value](map: Map[Key, Value], key: Key, value: Value) -> Map[Key, Value] {
  put(map, key, value)
}

fn init {
  let empty: Map[Int, Int] = Map::make()
  let one = { empty[1] = 1 } // Same as 等价于 let one = Map::op_set(empty, 1, 1)
  let _ = one[1] // Same as 等价于 let _ = Map::op_get(one, 1)
}