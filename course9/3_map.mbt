///|
struct Map[Key, Value] {
  data : Array[(Key, Value)]
}

///|
fn[Key, Value] Map::make() -> Map[Key, Value] {
  { data: [] }
}

///|
fn[Key : Eq, Value] Map::put(
  self : Map[Key, Value],
  key : Key,
  value : Value,
) -> Unit {
  match self.data.search_by(fn(pair) { pair.0 == key }) {
    Some(index) => self.data[index] = (key, value)
    None => self.data.push((key, value))
  }
}

///|
fn[Key : Eq, Value] Map::get(self : Map[Key, Value], key : Key) -> Value? {
  match self.data.search_by(fn(pair) { pair.0 == key }) {
    Some(index) => Some(self.data[index].1)
    None => None
  }
}

///|
#alias("_[_]")
fn[Key : Eq, Value] Map::get_item(self : Map[Key, Value], key : Key) -> Value? {
  self.get(key)
}

///|
#alias("_[_]=_")
fn[Key : Eq, Value] Map::set_item(
  self : Map[Key, Value],
  key : Key,
  value : Value,
) -> Unit {
  self.put(key, value)
}

///|
test "map basic operations" {
  let map : Map[String, Int] = Map::make()
  map.put("hello", 5)
  map.put("world", 10)
  inspect(map.get("hello"), content="Some(5)")
  inspect(map.get("world"), content="Some(10)")
  inspect(map.get("notfound"), content="None")
}

///|
test "map operator syntax" {
  let map : Map[String, Int] = Map::make()
  map["hello"] = 5
  map["world"] = 10
  inspect(map["hello"], content="Some(5)")
  inspect(map["world"], content="Some(10)")
  inspect(map["notfound"], content="None")
}

///|
test "map with duplicate keys" {
  let map : Map[String, Int] = Map::make()
  map.put("key", 1)
  map.put("key", 2)
  inspect(map.get("key"), content="Some(2)") // 返回更新后的值
}
