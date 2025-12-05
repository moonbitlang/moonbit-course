---
marp: true
math: mathjax
paginate: true
backgroundImage: url('../pics/background_moonbit.png')
headingDivider: 1
---

# 现代编程思想

## 特征与运算符重载

### 月兔公开课课程组

<!-- ssml
  大家好，欢迎来到由IDEA研究院基础软件中心为大家带来的现代编程思想公开课。
  今天是第九节课，主题是特征与运算符<phoneme alphabet="sapi" ph="chong 2 zai 4">重载</phoneme>。
<break time="500ms" />
-->

# 回顾

- 第六课：定义平衡二叉树
  - 定义一个更一般的二叉搜索树，允许存放任意类型的数据
    ```moonbit
    enum Tree[T] {
      Empty
      Node(T, Tree[T], Tree[T])
    }
    // 我们需要一个比较函数来比较值的大小以了解顺序
    // 负数表示小于，0表示等于，正数表示大于
    fn[T] insert(tree : Tree[T], value : T, compare : (T, T) -> Int) -> Tree[T] { ... }
    fn[T] delete(tree : Tree[T], value : T, compare : (T, T) -> Int) -> Tree[T] { ... }
    ```

- 第八课：定义循环队列
  - 我们需要类型的默认值来初始化数组
    ```moonbit
    fn[T] make(default : T) -> Queue[T] {
      { array: Array::make(5, default), start: 0, end: 0, length: 0 }
    }
    ```

<!-- ssml
  让我们先回顾一下之前课程中遇到的一些问题。
  在第六课中,我们定义了泛型版本的平衡二叉树,允许存放任意类型的数据。
  为了实现二叉搜索树,我们需要一个比较函数来比较值的大小,以了解顺序。
  比较函数返回负数表示小于,0表示等于,正数表示大于。
  因此,在插入和删除操作中,我们都需要将比较函数作为参数传进来。
<break time="500ms" />
  在第八课中,我们实现了泛型版本的循环队列。
  在构建数组的时候,我们需要提供默认值来初始化数组中的每个元素。
  一种方式则是根据类型来提供默认值，将默认值作为参数传进来。
  另一种方式，就是我们已经用过的，使用 Default 特征。
  第一种方式的问题在于，当我们对类型有较为复杂的需求时，参数的传递可能变得十分不便。
  更为重要的是,我们注意到一些函数其实是与类型相关联的，它的存在本身，反映了某些类型具有某些性质。
<break time="500ms" />
-->

# 方法

- 数据结构上的操作通常被定义为：
  - `fn T::method(self : T, ...) -> ...`
  - `fn T::new() -> T`
- 允许方法调用语法、级联运算语法、链式调用：`x..f().g()`
- 我们需要某个类型支持一些方法：
  - 类型的比较：`fn T::compare(self : T, other : T) -> Int`
  - 类型的默认值：`fn T::default() -> T`
  - 类型的输出：`fn T::to_string(self : T) -> String`
  - ……

<!-- ssml
  在前面的课程中，我们已经见识过方法。
  例如在定义各种数据结构时，我们使用类型名、两个冒号、方法名的方式定义数据结构的各种操作。
  并且，当第一个参数的类型刚好是方法关联的类型时，可以使用方法调用语法、级联运算语法和链式调用。
  有些情况下，对于某个类型，我们需要它支持一些方法。
  例如，我们需要某个类型中的值能够进行比较；
  又例如，我们需要某个类型总是可以直接构造一个默认值；
  或者，该类型的值 都能够被转换成字符串，等等。
<break time="500ms" />
-->

# 特征 Trait

- 特征的定义：`trait <特征名> [ : <超特征 + ...> ] { <方法类型签名>; ... }` 
  
  ```moonbit
  trait Compare : Eq {
    compare(Self, Self) -> Int // Self代表实现该特征的类型
  }
  trait Default {
    default() -> Self
  }
  ```

<!-- ssml
  此时，为了表达我们对于类型所具有的方法的需要，我们可以定义特征。
  特征是一系列方法的集合。
  特征定义的关键字为 trait,我们在内部定义一系列的方法的类型签名。
  其中,如果参数或返回值类型为实现该特征的类型,则用 Self 进行指代。
  例如这里的比较特征,<phoneme alphabet="ipa" ph="kəmˈpeə">compare</phoneme> 方法比较的是两个该类型的数据,那么我们用 Self 来声明参数类型。
  在定义中，我们还可以指定该特征在哪些超特征上进行扩展，也可以不指定。
  例如，这里定义的比较特征在 Eq 特征上进行扩展。
  关于扩展特征的含义，我们后面再详细介绍。
<break time="500ms" />
-->

# 特征 Trait

- 我们可以在泛型的参数上添加特征的要求
  - 限制参数的类型：`<类型参数> : <特征1 + 特征2 + ...>`
  - 在函数中使用特征定义的方法：`<类型参数>::<方法名>` 或 `<变量名>.<方法名>`
- 例子：
  ```moonbit 
  // 类型参数 T 应当满足 Default 特征
  fn[T : Default] make() -> Queue[T] { 
    {
      // 我们可以利用特征中的方法，返回类型为 Self，即 T
      array: Array::make(5, T::default()), 
      start: 0, end: 0, length: 0
    }
  }
  ```

<!-- ssml
  定义特征后，我们用冒号来描述 类型参数需要实现的特征。
  当类型参数需要实现多个特征时，特征之间通过加号分隔。
  例如下方的例子，make 函数需要类型 T 满足 Default 特征。
  在类型参数部分，使用冒号加上特证名的方式表达对类型 T 的约束。
  在函数中,我们就可以使用特征定义的方法，此处即为 default 方法，它产生一个 T 类型的默认值。
  特征方法的调用语法和普通方法一样，类型名、两个冒号、方法名，或者，当方法的第一个参数类型为 Self 类型时，也可以和普通方法一样，用变量名、一个点、方法名，进行调用。
<break time="500ms" />
-->

# 特征 Trait 

- 特征可以尽早发现使用不存在方法的错误
- 错误例子：
  ```moonbit
  struct BoxedInt { 
    value : Int 
  }

  test {
    let q : Queue[BoxedInt] = make() // 编译错误！BoxedInt 没有实现 Default
  }
  ```

<!-- ssml
  特征的限制可以让我们尽早发现使用不存在方法的错误。
  例如在下面的截图当中,我们试图构建一个 BoxedInt 的队列。
  但是我们并没有为 BoxedInt 类型实现 Default 特征。
  此时编译器就会及早发现问题,并且指出问题所在。
<break time="500ms" />
-->

# 特征 Trait

```moonbit
fn[T : Compare] insert(tree : Tree[T], value : T) -> Tree[T] {
  match tree {
    Empty => Node(value, Empty, Empty)
    Node(v, left, right) => {
      let result = value.compare(v) // 可以使用比较方法
      if result == 0 { 
        tree
      } else if result < 0 { 
        Node(v, insert(left, value), right)
      } else {
        Node(v, left, insert(right, value))
      }
    }
  }
}
```

<!-- ssml
  我们来看一个稍微复杂一些的特征使用例子。
  前面我们提到可以通过传入一个比较函数作为参数，向二叉搜索树中插入新的值。
  现在利用特征重新实现树的插入方法。
  我们声明类型参数 T 应当满足 <phoneme alphabet="ipa" ph="kəmˈpeə">compare</phoneme> 特征，只有这样，二叉搜索树才有意义。
  之后,我们在函数中使用 value 的 compare 方法 来进行比较。
  我们可以使用这个方法,是因为我们知道 T 满足比较特征,因此它必定拥有比较函数。
<break time="500ms" />
-->

# 特征实现

- 为类型实现某个特征：`impl <特征名> for <类型名> with <方法定义>`
- 特证实现需要实现特征中**所有**的方法
- 方法定义中的参数和返回值类型可以省略
  ```moonbit
  struct BoxedInt { value : Int }

  impl Default for BoxedInt with default() { // 可以省略类型标注
    { value: Int::default() } // Int::default() 为 0
  }

  test {
    let q : Queue[BoxedInt] = make()
  }
  ```

<!-- ssml
  要为类型实现某个特征，仅有对应的方法是不够的。
  月兔的特征需要用特殊的语法，明确指出某个类型实现了某个特征，并手动为这个类型实现特征的所有方法。
  实现的方式是，imple、特征名、<phoneme alphabet="sapi" ph="fo 4">for</phoneme>、类型名、with、方法定义。
  在下方的例子中，我们<phoneme alphabet="sapi" ph="wei 4">为</phoneme> Boxed Int 这个类型实现了 Default 特征。
  实现的方式是，提供一个 default 方法。在这里，我们使用了 Int 类型的默认值，也就是 0，来构建 Boxed Int 的默认值。
  月兔中的诸多类型，包括整数、浮点数、字符串等，都已经实现了 Default 特征。
  这样一来，我们就可以用 make 函数构造 Boxed Int 的队列了。
  注意到，我们并没有标注 default 方法的返回值类型。
  为类型实现特征时，可以省略方法参数的类型和返回值类型，因为这些信息在特征的定义中已经被包含了。
<break time="500ms" />
-->

# 特征实现

- 使用类型参数实现特征
  ```moonbit
  struct Boxed[T] { value : T }

  impl[T : Default] Default for Boxed[T] with default() { 
    { value: T::default() }
  }

  test {
    let q : Queue[Boxed[Int]] = make()
  }
  ```

<!-- ssml
  考虑一种更广泛的情况，Boxed 类型是一个泛型结构体类型，它包含一个值 value，其类型为泛型参数 T。
  此时，理所当然的，我们认为如果 T 有默认值，那么 Boxed T 也应该有默认值。
  我们可以结合类型参数来为泛型类型实现特征。
  在例子中，我们将泛型参数 T 和它的约束 用方括号包裹，写在 imple 关键字之后。
  在方法定义部分，就可以使用 T 的 default 方法构造默认值。
<break time="500ms" />
-->

# 特征实现

- 特征可以提供默认实现
  ```moonbit 
  trait Eq {
    equal(Self, Self) -> Bool 
    not_equal(Self, Self) -> Bool = _ // 这个方法有默认实现
  }

  impl Eq with not_equal(self, other) {
    !self.equal(other) // 使用 equal 实现 not_equal
  }

  impl[T : Eq] Eq for Boxed[T] with equal(self, other) {
    self.value.equal(other.value)
  }
  ```
- 手动实现会覆盖默认实现
  ```moonbit 
  impl[T : Eq] Eq for Boxed[T] with not_equal(self, other) {
    self.value.not_equal(other.value)
  }
  ```

<!-- ssml
  我们刚刚说过，实现一个特征时，需要为类型实现特征的所有方法。
  但有时，特征中的部分方法可以直接由其它方法推导得出。
  例如这里，我们定义了一个Eq，它包含两个方法，equal 和 not equal。
  我们知道，当一个类型实现了 equal 方法后，它自然就会有对应的 not equal 方法——只需将 equal 的结果取反就可以了。
  这种情况下，我们可以为 Eq 特征的 not equal 方法提供默认实现。
  首先，在特征定义的方法声明末尾，添加等号和下划线，表示这个方法有默认实现。
  然后，使用 imple、方法名、with、方法定义的语法，实现默认方法。
  在实现过程中，我们可以假设 self 已经是一个实现了 Eq 特征的类型，也就是说，在 not equal 的实现中，我们可以调用 equal 方法。
  这种情况下，如果要为某个类型实现 Eq 特征，只需实现 equal 一个方法就可以了，而无需手动实现 not equal 方法。当然，手动实现 not equal 也是可以的，它会覆盖默认实现。
<break time="500ms" />
-->

# 特征实现

- 不包含无默认实现方法的特征，也需要显式声明实现
  
  ```moonbit check 
  trait Animal {
    speak() -> String = _
  }
  impl Animal with speak() { "hi" }

  struct Dog {}
  impl Animal for Dog     // 显式声明实现
  ```

<!-- ssml
  另外，在月兔中，
  对于不包含无默认实现方法的特征，比如例子中的 Animal 特征，
  也需要显式声明某个类型实现了该特征，语法是，imple、特征名、<phoneme alphabet="sapi" ph="fo 4">for</phoneme>、类型名，不包含 with 和方法定义。
  例子中的 Dog 类型，我们为它实现了 Animal 特征，尽管没有任何方法定义。
  但如果不进行该声明，Dog 类型就不会被认为实现了这个特征。
  <break time="500ms" />
-->

# 表：利用特征实现

- 一个表是键值对的集合
  - 对于每一个 **键** 存在一个对应 **值**
  - 例：`{ 0 -> "a", 5 -> "Hello", 7 -> "a"}`

```moonbit
type Map[K, V]

// 创建表
fn[K, V] Map::make() -> Map[K, V] { ... }

// 添加键值对，或更新键对应值
fn[K, V] Map::put(map : Map[K, V], key : K, value : V) -> Unit { ... }

// 获取键对应值
fn[K, V] Map::get(map : Map[K, V], key : K) -> Option[V] { ... }
```

<!-- ssml
  我们现在来看一个例子,利用特征来实现一个简单的表。
  表是 键 到 值 的映射。
  例如在这个映射中,0对应字符串a,5对应字符串Hello,7对应字符串a。
  其中对于每一个键存在一个值,值可以重复,键不能重复，一个键不能同时对应两个值。
  我们对于它定义操作如下：我们应当可以创建表；
  可以添加键值对或更新键对应的值；
  也可以获得键所对应的值。
  当然,因为表中不一定有我们想要查询的键值对,因此我们用 Option 来包裹我们的查询结果。
<break time="500ms" />
-->

# 表：利用特征实现

- 表的简易实现
  - 利用数组+二元组存储键值对
  - 添加/更新时向数组末尾添加键值对
  - 查询时从数组开始遍历，找到键即返回
- 简易实现需要判断存储的键值对是否为搜索的键
  - 键应当满足 `Eq` 特征
  ```moonbit
  fn[K : Eq, V] Map::put(map : Map[K, V], key : K, value : V) -> Unit { ... }
  fn[K : Eq, V] Map::get(map : Map[K, V], key : K) -> Option[V] { ... }
  ```

<!-- ssml
  我们利用数组进行最简单的实现。
  我们在数组中存储二元组,每次将新的值添加在数组末尾,查询时从数组开始遍历。
  这样当有重复的键时,我们会找到最新添加的值。
  这个简易实现要求我们的键，也就是类型 K，满足 Eq 特征,这样才能判断 是不是我们所要查找的值。
  因此,我们在 put 和 get 方法中对类型变量添加特征的定义,限制 K 应当可以进行相等的判断。
<break time="500ms" />
-->

# 表：利用特征实现

- 我们以数组+二元组作为表
```moonbit check
// 我们定义一个类型Map，包含一个数组存储键值对
struct Map[K, V] {
  data : Array[(K, V)]
}

fn[K, V] Map::make() -> Map[K, V] {
  { data: [] }
}

fn[K : Eq, V] Map::put(self : Map[K, V], key : K, value : V) -> Unit {
  match self.data.search_by(fn(pair) { pair.0 == key }) {
    Some(index) => self.data[index] = (key, value)
    None => self.data.push((key, value))
  }
}
```

<!-- ssml
  我们利用数组和二元组进行实现。
  我们定义一个结构体 Map,它包含一个数组字段,元素为键值对的二元组。
  生成这个新类型的表很简单,我们只需要用空数组作为初始值即可。
  添加操作使用数组的 search by 方法,通过一个函数来查找是否已经存在相同的键。
  如果找到了,就更新该位置的值。
  如果没有找到,就使用数组的 push 方法,将新的键值对添加到数组末尾。
<break time="500ms" />
-->

# 表：利用特征实现

- 我们以数组+二元组作为表
```moonbit check
fn[K : Eq, V] Map::get(self : Map[K, V], key : K) -> Option[V] {
  match self.data.search_by(fn(pair) { pair.0 == key }) {
    Some(index) => Some(self.data[index].1)
    None => None
  }
}
```

<!-- ssml
  当我们取值的时候,我们需要进行相等判断,因此这里有相等的特征限制。
  我们使用数组的 search by 方法来查找键值对。
  search by 接受一个函数,这个函数对每个元素进行判断。
  我们通过检查元组的第一个元素是否等于要查询的键来进行查找。
  如果找到了,那么我们返回对应的值,也就是元组的第二个元素。
  否则,返回 None。
<break time="500ms" />
-->

# 扩展特征

- 子特征可以在超特征上进行扩展：`trait Sub: Super1 + Super2 + ...`
  ```moonbit check 
  trait Position {
    pos(Self) -> (Int, Int)
  }

  trait Draw {
    draw(Self, Int, Int) -> Unit
  }

  trait Object: Position + Draw {}
  ```

- 实现子特征必须先实现超特征
  ```moonbit
  impl Position for T with pos(...) { ... }
  impl Draw for T with draw(...) { ... }
  impl Object for T
  ```

<!-- ssml
  一些情况下，某个特征是对另一些特征的扩展。
  比如我们之前见过的，<phoneme alphabet="ipa" ph="kəmˈpeə">compare</phoneme> 特征是对 Eq 特征的扩展。我们将它们的关系称作 子特征 与 超特征。
  一个子特征可以有多个超特征。
  在定义特征时，如果该特征在其它超特征上进行扩展，则使用冒号的语法进行声明。
  当有多个超特征时，用加号进行分隔。
  在例子中，我们先定义了两个特征，Position 和 Draw，然后定义了一个新的特征 Object。
  它是 Position 和 Draw 的子特征，这意味着，如果一个类型需要实现 Object 特征，首先它需要实现 Position 和 Draw 特征。
<break time="500ms" />
-->

# 运算符重载

- 运算符和特征方法并没本质区别
- 月兔允许通过实现特定特征来重载运算符
  - 算术运算：`+ Add`, `- Sub`, `* Mul`, `/ Div`, `% Mod`, `- Neg`
  - 相等判断：`== Eq`
  - 比较运算：`< Compare`
  - 位运算：`| BitOr`, `& BitAnd`, `^ BitXOr`, `<< Shl`, `>> Shr`
- 实现特定的运算符方法：
  ```moonbit 
  pub trait Add {
    add(Self, Self) -> Self
  }
  ```

<!-- ssml
  接下来我们介绍运算符<phoneme alphabet="sapi" ph="chong 2 zai 4">重载</phoneme>。
  首先回顾一个关键的知识，那就是月兔中的运算符，和普通的函数没有本质区别。
  只不过，运算符通常可以用来处理不同类型的运算。
  比如加法运算符，既可以用来表示整数相加，也可以用来表示浮点数相加。
  这种对不同类型调用不同具体运算符实现的过程 叫运算符<phoneme alphabet="sapi" ph="chong 2 zai 4">重载</phoneme>。
  这和特征提供给我们的能力是一样的。
  月兔允许通过实现特定特征来为我们自己定义的类型实现运算符，也就是运算符<phoneme alphabet="sapi" ph="chong 2 zai 4">重载</phoneme>。
  月兔提供了多种运算符特征，总共可以分为算术运算、相等判断、比较运算、位运算这几大类。
  实现特定的运算符特征后，我们就可以使用运算符来对数据进行操作。
  例如，实现 Add 特征的 add 方法,则允许我们使用加号。
  通过运算符<phoneme alphabet="sapi" ph="chong 2 zai 4">重载</phoneme>,我们可以更自然地使用自定义的数据类型。
<break time="500ms" />
-->

# 运算符重载

```moonbit
impl Eq for BoxedInt with equal(i : BoxedInt, j : BoxedInt) -> Bool {
  i.value == j.value
}

impl Add for BoxedInt with add(i, j) { 
  { value: i.value + j.value }
}

test {
  inspect({ value: 10 } == { value: 100 }, content="false")
  inspect({ value: 10 } + { value: 100 }, content="{value: 110}")
}
```

<!-- ssml
  在例子中，我们<phoneme alphabet="sapi" ph="wei 4">为</phoneme> Boxed Int 类型 实现了 EQ 特征 和 Add 特征。
  此后，我们就可以使用等号运算符和加号运算符，来对 Boxed Int 类型的值进行操作。
<break time="500ms" />
-->

# 下标运算符

- 下标运算符不通过特征实现，而是通过 `#alias` 注解
  - 取值运算符：`#alias("_[_]")`
  - 设值运算符：`#alias("_[_]=_")`

```moonbit
#alias("_[_]")
fn[K : Eq, V] Map::get(self : Map[K, V], key : K) -> Option[V] { ... }

#alias("_[_]=_")
fn[K : Eq, V] Map::put(self : Map[K, V], key : K, value : V) -> Unit { ... }

test {
  let map : Map[String, Int] = Map::make()
  map["hello"] = 5
  inspect(map["hello"], content="Some(5)")
}
```

<!-- ssml
  下标运算符与算术运算符不同,它不是通过特征实现的,而是通过在方法定义处使用 alias 注解实现。
  对于取值运算符,我们使用 下划线 加上 方括号包裹下划线的形式。
  对于设值运算符,在取值运算符的表示后方 添加一个等号和一个下划线。
  这两个语法的每一个下划线，都对应着函数定义中的一个参数。
  在表的例子中,我们可以用该语法来获取和设置键值对。
  在代码的第1行和第4行，我们分别为定义的 get 和 put 方法添加注解。
  接下来，我们在第9行通过设置运算符，调用 put 方法将 hello 对应的值设置成了5。
  然后在第10行，通过取值运算符，调用 get 方法取出 hello 对应的值。
<break time="500ms" />
-->

# 特征对象

- 特征对象允许在运行时实现多态
- 使用 `value as &TraitName` 语法将值转换为特征对象（类型擦除）

  ```moonbit
  trait Animal {
    speak(Self) -> String
  }

  struct Duck { name : String }
  impl Animal for Duck with speak(self) { "\{self.name}: quack!" }

  struct Fox { name : String }
  impl Animal for Fox with speak(self) { "\{self.name}: ring-ding-ding!" }

  test {
    let animals : Array[&Animal] = [Duck::{ name: "Donald" }, Fox::{ name: "Nick" }]
    for animal in animals {
      println(animal.speak()) // Donald: quack! Nick: ring-ding-ding!
    }
  }
  ```

<!-- ssml
  特征最强大之处，在于我们可以在需要的时候，将特征当做类型来使用。
  这种机制叫作特征对象。特征对象允许我们在运行时实现多态。
  这是继泛型之后，又一种强大的实现多态的机制。
  特征对象的语法是在特征名前加一个 ampersand 符号。
  我们可以使用 as 关键字，将一个 value 转换成一个特征对象来使用。
  例如，在例子的第12行代码，我们想要一个所有实现了 Animal 特征的类型构成的数组，而非某个特定类型的数组。
  但特征本身是不能作为类型使用的，此时我们就可以使用特征对象。
  这样，Duck 和 Fox 这两个类型，由于都实现了 Animal 特征，于是都可以放进这个数组。
  而 Animal 特征对象可以调用 speak 方法，于是我们可以用一个循环访问数组中所有的动物，统一调用它们的 speak 方法。
  由于此时特征对象已经失去了原本的类型信息，因此这种技术也被称作类型擦除。
<break time="500ms" />
-->

# 特征对象和对象安全

- 并非所有的特征都可以创建特征对象
- 必须满足对象安全，所有的方法：
  - 第一个参数是 `Self` 
  - 方法的类型中只能出现一个 `Self` 

  ```moonbit check 
  trait TraitA {
    f(Self) -> Unit 
  } // 对象安全，可以使用 &TraitA

  trait TraitB {
    g(Self) -> Int 
    h() -> Self // 第一个参数不是 Self，返回值是 Self
  } // 不安全，不可以使用 &TraitB
  ```

<!-- ssml
  并非所有的特征都可以使用特征对象。
  可以创建特征对象的特征必须满足对象安全。
  所谓特征安全，指的是这个特征的所有方法类型都必须包含一个 Self 类型，而且这个 Self 必须是第一个参数的类型。
  例子中的 trait A 是对象安全的，它的方法 f 满足上述性质。
  而 trait B 不是对象安全的，因为它的方法 h 的第一个参数不是 Self，而且返回值包含了 Self 类型。
  对于 trait B，就无法使用特征对象。
  为什么特征对象会有这样的限制呢？
  这是因为特征对象的实现原理，是将方法的具体实现 绑定到了一个值上。
  在月兔中，这个值就是方法的第一个参数。
<break time="500ms" />
-->

# 特征对象和对象安全

- 反例：第一个参数不是 `Self`

  ```moonbit
  trait Default {
    default() -> Self // 第一个参数不是 Self，不安全
  }

  test {
    let x : &Default = ...
    // 没有任何方式构造默认值
  }
  ```

<!-- ssml
  为了更深刻理解对象安全，我们假设没有上述限制，看看会发生什么。
  首先，如果参数中没有 Self 类型，比如 Default 特征。
  假设我们可以构造 Default 特征对象 x，现在如何获取默认值呢？
  答案是没有任何办法做到这一点，因为 default 函数没有一个 self 参数，
  无法将特定的 default 方法实现绑定到一个值上。
<break time="500ms" />
-->

# 特征对象和对象安全

- 反例：多个 `Self` 参数

  ```moonbit
  trait Compare {
    compare(Self, Self) -> Int // Self 出现了多次，不安全
  }

  test {
    let x : &Compare = ... 
    let y : &Compare = ...
    x.compare(y) // 无从得知 x 和 y 是同一个类型，
  }
  ```

<!-- ssml
  在 <phoneme alphabet="ipa" ph="kəmˈpeə">compare</phoneme> 特征中，compare 方法的两个参数都是 Self，
  这也违反了对象安全。
  假设我们可以构造两个特征对象 x 和 y，并试图进行比较。
  由于 <phoneme alphabet="ipa" ph="kəmˈpeə">compare</phoneme> 方法要求两个参数是同一个类型，
  而此时 x 和 y 都已经失去了原本的类型信息，我们无从得知这两个变量是否为同一个类型，
  所以这行代码无法通过类型检查。
<break time="500ms" />
-->

# 特征的自动派生

- 对于一些常用的特征，月兔可以自动生成实现
- 使用 `derive` 关键字在类型定义后声明

  ```moonbit
  struct Point { x : Int; y : Int } derive(Eq, Show)

  enum Status { Active; Inactive } derive(Eq, Show, Default)
  ```

- 常见的可派生特征：
  - `Eq`：判断相等性
  - `Compare`：比较大小
  - `Show`：转换为字符串
  - `Default`：提供默认值

<!-- ssml
  最后，我们介绍特征的自动派生。
  对于一些常用的特征,手动实现会很繁琐。
  月兔可以自动为我们生成这些特征的实现。
  我们使用 <phoneme alphabet="ipa" ph="dɪˈraɪv">derive</phoneme> 关键字,在类型定义的最后声明需要派生的特征。
  例如在这个例子中,我们<phoneme alphabet="sapi" ph="wei 4">为</phoneme> Point 结构体派生了 Eq 和 Show 特征。
  为 Status 枚举类型实现了 Eq、Show、Default 特征。
  月兔内置的常用特征 大多数都是可以直接派生的。
  那么，自动派生得到的特征实现一般是什么样的实现呢？
<break time="500ms" />
-->

# Eq 特征的自动派生

- `Eq` 特征用于判断相等性
- 结构体派生时，按字段定义顺序逐一比较
- 特征 `T` 的派生要求所有内部类型（结构体的字段，枚举的负载值类型）都实现了特征 `T`

  ```moonbit check
  struct Point { x : Int; y : Int } derive(Eq)

  test {
    let p1 = { x: 1, y: 2 }
    let p2 = { x: 1, y: 2 }
    let p3 = { x: 2, y: 2 }
    let p4 = { x: 1, y: 1 }
    inspect(p1 == p2, content="true")  // p1.x == p2.x && p1.y == p2.y
    inspect(p1 == p3, content="false") // p1.x != p2.x
    inspect(p1 == p4, content="false") // p1.y != p2.y
  }
  ```

<!-- ssml
  我们来看第一个例子，我们定义一个 Point 类型，它包含两个 Int 类型的字段 x 和 y。
  我们使用 <lang xml:lang="en-US"><phoneme alphabet="ipa" ph="dɪˈraɪv">derive</phoneme></lang> Eq 来为它自动派生 Eq 特征。
  通过测试内容可以看到，当且仅当两个点的 x 和 y 都分别相等时，两个点才被认为相等。
  这符合我们的直觉。
  也就是说，为结构体自动派生 Eq 特征时，会逐一判断结构体的所有字段是否分别相等。
  只有所有字段都分别相等，两个值才被判定为相等。
  派生要求所有字段的类型也必须实现 Eq 特征。
<break time="500ms" />
-->

# Compare 特征的自动派生

- `Compare` 特征用于比较大小
- 枚举类型自动派生 `Compare` 会按照不同情形定义的先后顺序

  ```moonbit check
  enum Weekday {
    Monday
    Tuesday
    Wednesday
    Thursday
    Friday
    Saturday
    Sunday
  } derive(Eq, Compare)

  test {
    inspect(Monday < Tuesday, content="true")
    inspect(Sunday < Monday, content="false")
    inspect(Friday >= Friday, content="true")
  }
  ```

<!-- ssml
  再来看第二个例子。
  自动派生 <phoneme alphabet="ipa" ph="kəmˈpeə">compare</phoneme> 特征时，
  需要保证该类型已经实现了 Eq 特征。
  对于枚举类型，会按照不同情形定义的先后顺序 来定义从小到大的顺序。
  也就是说，由于星期<phoneme alphabet="sapi" ph="yi 1">一</phoneme>定义在最前面，因此它比其它的值都要小，而星期天定义在最后，它比所有其它值都要大。
<break time="500ms" />
-->

# 总结

- 本节课我们展示了：
  - 定义特征、类型约束、实现特征
  - 运算符重载
  - 特征对象
  - 特征的自动派生

<!-- ssml
  总结一下。
  本节课我们展示了如何在月兔中定义特征、使用特征约束类型、实现特征。
  还学习了使用运算符<phoneme alphabet="sapi" ph="chong 2 zai 4">重载</phoneme>，以及特征对象和自动派生特征的相关知识。
  以上便是本节课的全部内容,感谢大家的观看。
<break time="500ms" />
-->
