///|
struct MyArray[T] {
  mut content : FixedArray[T]
  mut length : Int
}

///|
impl[T : Show] Show for MyArray[T] with output(self, logger) {
  self.content.output(logger)
}

///|
test "Corelib" {
  let arr = Array::make(1, 0)
  arr.set(0, 1)
  arr.push(5)
  arr.append(arr)
  arr.insert(0, 2)
  inspect(arr.get(0), content="Some(2)")
  inspect(arr, content="[2, 1, 5]")
}

///|
fn[T] MyArray::make(len : Int, init : T) -> MyArray[T] {
  { content: FixedArray::make(len, init), length: len }
}

///|
fn[T] MyArray::length(self : MyArray[T]) -> Int {
  self.length
}

///|
fn[T] MyArray::set(self : MyArray[T], idx : Int, val : T) -> Unit {
  guard idx >= 0 && idx < self.length
  self.content.set(idx, val)
}

///|
fn[T] MyArray::get(self : MyArray[T], idx : Int) -> T? {
  guard idx >= 0 && idx < self.length else { None }
  self.content.get(idx)
}

///|
fn[T : Default] MyArray::push(self : MyArray[T], val : T) -> Unit {
  if self.length == self.content.length() {
    self.realloc()
  }
  self.content.set(self.length, val)
  self.length = self.length + 1
}

///|
fn[T : Default] MyArray::insert(self : MyArray[T], idx : Int, val : T) -> Unit {
  if self.length == self.content.length() {
    self.realloc()
  }
  for i = self.length - 1; i >= idx; i = i - 1 {
    self.content.set(i + 1, self.content[i])
  }
  self.content.set(idx, val)
  self.length = self.length + 1
}

///|
fn[T : Default] MyArray::realloc(self : MyArray[T]) -> Unit {
  let old_cap = self.length()
  let new_cap = if old_cap == 0 { 8 } else { old_cap * 2 }
  let new_content = FixedArray::make(new_cap, T::default())
  for i = 0; i < old_cap; i = i + 1 {
    new_content.set(i, self.content[i])
  }
  self.content = new_content
}

// fn[T : Default] MyArray::remove(self : MyArray[T]) -> Unit {
  
// }

///|
test "My array" {
  let myarr = MyArray::make(1, 0)
  myarr.set(0, 10)
  myarr.push(4)
  inspect(myarr, content="[10, 4]")
  myarr.insert(1, 2)
  myarr.insert(1, 3)
  inspect(myarr, content="[10, 3, 2, 4]")
}

fn[T] MyArray::each(self : MyArray[T], f : (T) -> Unit) -> Unit {
  for i = 0; i < self.length; i = i + 1 {
    let elem = self.get(i)
    guard elem is Some(elem)
    f(elem)
  }
}

///|
test {
  let arr1 = Array::make(5, 0)
  let arr2 = Array::make(5, 0)
  arr1..push(1)..push(2)..push(3)
  arr1.each(fn(elem) { arr2.insert(0, elem) })
  inspect(arr2.get(0), content="Some(3)")
  inspect(arr2.get(1), content="Some(2)")
  inspect(arr2.get(2), content="Some(1)")
  inspect(arr2, content="[3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]")
}
