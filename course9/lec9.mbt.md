---
marp: true
math: mathjax
paginate: true
backgroundImage: url('../pics/background_moonbit.png')
headingDivider: 1
---

# 现代编程思想

## 接口

### Hongbo Zhang

# 回顾

- 第六课：定义平衡二叉树
  - 我们定义一个更一般的二叉搜索树，允许存放任意类型的数据
  ```moonbit
  enum Tree[T] {
    Empty
    Node(T, Tree[T], Tree[T])
  }

  // 我们需要一个比较函数来比较值的大小以了解顺序
  // 负数表示小于，0表示等于，正数表示大于
  fn[T] insert(self: Tree[T], value: T, compare: (T, T) -> Int) -> Tree[T] { ... }
  fn[T] delete(self: Tree[T], value: T, compare: (T, T) -> Int) -> Tree[T] { ... }
  ```
- 第八课：定义循环队列
  - 我们需要类型的默认值来初始化数组
  ```moonbit
  fn[T] make(default: T) -> Queue[T] {
    { array: Array::make(5, default), start: 0, end: 0, length: 0 }
  }
  ```

# 方法

- 我们注意到一些与类型相关联的函数
  - 类型的比较：`fn T::compare(self: T, other: T) -> Int`
  - 类型的默认值：`fn T::default() -> T`
  - 类型的输出：`fn T::to_string(self: T) -> String`
  - ……
- 我们将这类函数称为**方法**

# 接口 Trait

- 我们通过接口定义一系列方法的实现需求
```moonbit
trait Compare : Eq {
  compare(Self, Self) -> Int // Self代表实现该接口的类型
}
trait Default {
  default() -> Self
}
```
- 月兔中的接口是名义上的，即必须声明为特定的接口实现方法

# 接口 Trait

- 我们可以在泛型的参数上添加接口的要求
  - 限制参数的类型：`<类型参数> : <接口>`
  - 在函数中使用接口定义的方法：`<类型参数>::<方法名>`

```moonbit
fn[T : Default] make() -> Queue[T] { // 类型参数T应当满足Default接口
  { 
    array: Array::make(5, T::default()), // 我们可以利用接口中的方法，返回类型为Self，即T
    start: 0,  end: 0,  length: 0 
  } 
}
```

- 接口可以尽早发现使用不存在方法的错误
![height:150px](../pics/no_method.png)

# 接口 Trait

```moonbit
fn[T : Compare] insert(tree : Tree[T], value : T) -> Tree[T] {
  // 类型参数T应当满足比较接口
  match tree {
    Empty => Node(value, Empty, Empty) 
    Node(v, left, right) =>  
      if T::compare(value, v) == 0 { // 可以使用比较方法
        tree
      } else if T::compare(value, v) < 0 { // 可以使用比较方法
        Node(v, insert(left, value), right)
      } else {
        Node(v, left, insert(right, value))
      }
  }
}
```

# 方法的定义

- 方法定义以`<类型>::`为函数名称起始
```moonbit
struct BoxedInt { value : Int }

fn BoxedInt::default() -> BoxedInt {
  { value : Int::default() } // 使用整数的默认值 0
}

impl Default for BoxedInt with default() { // 可以省略类型标注
  BoxedInt::default()
}

test {
  let array: Queue[BoxedInt] = make()
}
```

# 链式调用

- 月兔允许利用`<变量>.<方法>()`的形式调用方法
  - 方法的第一个参数为该类型的数值
```moonbit
fn BoxedInt::plus_one(b: BoxedInt) -> BoxedInt {
  { value : b.value + 1 }
}
fn BoxedInt::plus_two(self: Self) -> Self { // 可以用 Self 代替参数名称
  { value : self.value + 2}
}

fn init {
  let _five = { value: 1 }.plus_one().plus_one().plus_two()
  // 无需进行深层嵌套，方便理解
  let _five = BoxedInt::plus_two(
    BoxedInt::plus_one(BoxedInt::plus_one({value: 1}))
  )
}
```

# 派生定义

- 简单的接口可以自动生成，在定义最后声明`derive(<接口>)`即可

```moonbit
struct BoxedInt { value : Int } derive(Default, Eq, Compare, Show)
```

- 需要数据结构内部的数据同样实现接口

# 表：利用接口实现

- 一个表是键值对的集合
  - 对于每一个 **键** 存在一个对应 **值**
  - 例：`{ 0 -> "a", 5 -> "Hello", 7 -> "a"}`

```moonbit
type Map[Key, Value]

// 创建表
fn[Key, Value] make() -> Map[Key, Value] { ... }
// 添加键值对，或更新键对应值
fn[Key, Value] put(map: Map[Key, Value], key: Key, value: Value) -> Map[Key, Value] { ... }
// 获取键对应值
fn[Key, Value] get(map: Map[Key, Value], key: Key) -> Option[Value] { ... }
```

# 表：利用接口实现

- 表的简易实现
  - 利用列表+二元组存储键值对
  - 添加/更新时向列表前添加键值对
  - 查询时从列表前开始，找到键即返回
- 简易实现需要判断存储的键值对是否为搜索的键
  - 键应当满足相等接口
  ```moonbit
  fn[Key: Eq, Value] get(map: Map[Key, Value], key: Key) -> Option[Value] { ... }
  ```

# 表：利用接口实现

- 我们以列表+二元组作为表
```moonbit
// 我们定义一个类型Map，其实际值为List[(Key, Value)]
type Map[Key, Value] List[(Key, Value)]

fn[Key, Value] make() -> Map[Key, Value] { 
  Map(Nil)
}

fn[Key, Value] put(map: Map[Key, Value], key: Key, value: Value) -> Map[Key, Value] { 
  let Map(original_map) = map
  Map( Cons( (key, value), original_map ) )
}
```

# 表：利用接口实现

- 我们以列表+二元组作为表
```moonbit
fn[Key: Eq, Value] get(map : Map[Key, Value], key : Key) -> Option[Value] {
  fn aux(list : List[(Key, Value)]) -> Option[Value] {
    match list {
      Nil => None
      Cons((k, v), tl) => if k == key { // Key实现了Eq接口，因此可以利用==比较
        Some(v)
      } else {
        aux(tl)
      }
    }
  }

  aux(map.inner()) // 利用 .inner() 取出实际的值
}
```

# 自定义运算符

- 月兔允许自定义部分运算符：比较、加减乘除、取值、设值
- 通过实现特定接口
- 特别的，对于取值、设值，通过定义特定名称、类型的方法即可实现

```moonbit
impl Eq for BoxedInt with op_equal(i: BoxedInt, j: BoxedInt) -> Bool {
  i.value == j.value
}
impl Add for BoxedInt with op_add(i, j) { // 可以省略
  { value: i.value + j.value }
}

test {
  inspect({ value: 10 } == { value: 100 }, content="false")
  inspect({ value: 10 } + { value: 100 }, content="{value: 110}")
}
```

# 自定义运算符

- 月兔允许自定义部分运算符：比较、加减乘除、取值、设值
- 通过实现特定接口
- 特别的，对于取值、设值，通过定义特定名称、类型的方法即可实现

```moonbit
// 使用：map [ key ]
fn[Key: Eq, Value] Map::op_get(map: Map[Key, Value], key: Key) -> Option[Value] {
  get(map, key)
}
// 使用：map [ key ] = value
fn[Key, Value] Map::op_set(map: Map[Key, Value], key: Key, value: Value) -> Map[Key, Value] {
  put(map, key, value)
}

test {
  let empty: Map[Int, Int] = make()
  let one = { empty[1] = 1 } // 等价于 let one = Map::op_set(empty, 1, 1)
  let _ = one[1] // 等价于 let _ = Map::op_get(one, 1)
}
```

# 总结

- 本章节展示了如何在月兔中
  - 定义接口 Trait并修饰类型变量
  - 实现方法及自定义运算符
- 以及简单的表的实现


