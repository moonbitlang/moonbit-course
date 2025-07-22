///| Symbolic differentiation 符号微分
enum Symbol {
  Constant(Double)
  Var(Int)
  Add(Symbol, Symbol)
  Mul(Symbol, Symbol)
} derive(Show)

///|
fn Symbol::constant(d : Double) -> Symbol {
  Constant(d)
}

///|
fn Symbol::variable(i : Int) -> Symbol {
  Var(i)
}

///|
impl Add for Symbol with op_add(f1 : Symbol, f2 : Symbol) -> Symbol {
  // Add(f1, f2) // Without simplification 无化简实现
  // With simplification 以下为化简实现
  match (f1, f2) {
    (Constant(0.0), a) => a
    (Constant(a), Constant(b)) => Constant(a + b)
    (a, Constant(_) as c) => c + a
    (Mul(n, Var(x1)), Mul(m, Var(x2))) if x1 == x2 => Mul(m + n, Var(x1))
    _ => Add(f1, f2)
  }
}

///|
impl Mul for Symbol with op_mul(f1 : Symbol, f2 : Symbol) -> Symbol {
  // Mul(f1,f2) // Without simplification 无化简实现
  // With simplification 以下为化简实现
  match (f1, f2) {
    (Constant(0.0), _) => Constant(0.0)
    (Constant(1.0), a) => a
    (Constant(a), Constant(b)) => Constant(a * b)
    (a, Constant(_) as c) => c * a
    _ => Mul(f1, f2)
  }
}

///|
fn compute(self : Symbol, input : Array[Double]) -> Double {
  match self {
    Constant(d) => d
    Var(i) => input[i] // get value following index 根据下标取值
    Add(f1, f2) => f1.compute(input) + f2.compute(input)
    Mul(f1, f2) => f1.compute(input) * f2.compute(input)
  }
}

///|
/// val is the index of the variable to be differentiated 
/// val代表当前微分的变量
fn differentiate(self : Symbol, val : Int) -> Symbol {
  match self {
    Constant(_) => Constant(0.0)
    Var(i) => if i == val { Constant(1.0) } else { Constant(0.0) } // determine if is the variable to be differentiated 根据下标判断是否为微分对象
    Add(f1, f2) => f1.differentiate(val) + f2.differentiate(val)
    Mul(f1, f2) => f1 * f2.differentiate(val) + f1.differentiate(val) * f2
  }
}

///|
/// 5 x^2 + y
fn example() -> Symbol {
  Symbol::constant(5.0) * Symbol::variable(0) * Symbol::variable(0) +
  Symbol::variable(1)
}

///|
test "Symbolic differentiation 符号微分" {
  let input = [10.0, 100.0]
  let symbol : Symbol = example()
  assert_eq(symbol.compute(input), 600.0)
  // Expression of df/dx 关于 x 的偏微分表达式树
  inspect(symbol.differentiate(0), content="Mul(Constant(10), Var(0))")
  assert_eq(symbol.differentiate(0).compute(input), 100.0)
  assert_eq(symbol.differentiate(1).compute(input), 1.0)
}

///| Abstraction of computation 对运算的抽象
trait Number: Add + Mul {
  constant(Double) -> Self
  value(Self) -> Double
}

///| Implement abstraction for Double 对浮点数实现抽象
impl Number for Double with constant(d : Double) -> Double {
  d
}

///|
impl Number for Double with value(d : Double) -> Double {
  d
}

///| Compute max with native control flow 利用原生控制流求最大值
fn[N : Number] max(x : N, y : N) -> N {
  if x.value() > y.value() {
    x
  } else {
    y
  }
}

///| Rectified linear unit 线性整流函数
fn[N : Number] relu(x : N) -> N {
  max(x, N::constant(0.0))
}

///| Forward differentiation: dual number 前向微分，二元数
struct Forward {
  value : Double
  derivative : Double
} derive(Show)

///|
/// diff: weather differentiate this variable
/// diff：是否对当前变量求偏微分
fn Forward::variable(d : Double, diff : Bool) -> Forward {
  { value: d, derivative: if diff { 1.0 } else { 0.0 } }
}

///|
impl Add for Forward with op_add(f : Forward, g : Forward) -> Forward {
  { value: f.value + g.value, derivative: f.derivative + g.derivative } // f' + g',,,
}

///|
impl Mul for Forward with op_mul(f : Forward, g : Forward) -> Forward {
  {
    value: f.value * g.value,
    derivative: f.value * g.derivative + g.value * f.derivative, // f * g' + g * f',,,
  }
}

///|
impl Number for Forward with constant(d : Double) -> Forward {
  { value: d, derivative: 0.0 }
}

///|
impl Number for Forward with value(f : Forward) -> Double {
  f.value
}

///|
test "Forward differentiation 前向微分" {
  // Compute using abstraction 利用抽象进行计算值
  assert_eq(relu(10.0), 10.0)
  assert_eq(relu(-10.0), 0.0)
  // Forward differentiation with abstraction 利用抽象进行前向微分
  inspect(
    relu(Forward::variable(10.0, true)),
    content="{value: 10, derivative: 1}",
  )
  inspect(
    relu(Forward::variable(-10.0, true)),
    content="{value: 0, derivative: 0}",
  )
  // f(x, y) = x * y => df/dy(10, 100)
  inspect(
    Forward::variable(10.0, false) * Forward::variable(100.0, true),
    content="{value: 1000, derivative: 10}",
  )
}

///|
/// Backward differentiation 后向微分
struct Backward {
  value : Double
  propagate : () -> Unit
  backward : (Double) -> Unit // update the partial derivative of the current path 更新当前路径获得的偏微分
} derive(Show)

///|
fn Backward::variable(value : Double, diff : Ref[Double]) -> Backward {
  { value, propagate: () => (), backward: d => diff.val += d } // accumulate partial derivative 累加偏微分
}

///|
/// df / df = 1.0
fn Backward::backward(b : Backward) -> Unit {
  (b.propagate)()
  (b.backward)(1.0)
}

///|
impl Number for Backward with constant(d : Double) -> Backward {
  { value: d, propagate: () => (), backward: _ => () }
}

///|
impl Number for Backward with value(backward : Backward) -> Double {
  backward.value
}

///|
impl Add for Backward with op_add(b1 : Backward, b2 : Backward) -> Backward {
  let counter = { val: 0 }
  let cumul = { val: 0.0 }
  {
    value: b1.value + b2.value,
    propagate: fn() {
      counter.val += 1
      if counter.val == 1 {
        (b1.propagate)()
        (b2.propagate)()
      }
    },
    backward: fn(diff) {
      counter.val -= 1
      cumul.val += diff
      if counter.val == 0 {
        (b1.backward)(cumul.val)
        (b2.backward)(cumul.val)
      }
    },
  }
}

///|
impl Mul for Backward with op_mul(b1 : Backward, b2 : Backward) -> Backward {
  let counter = { val: 0 }
  let cumul = { val: 0.0 }
  {
    value: b1.value * b2.value,
    propagate: fn() {
      counter.val += 1
      if counter.val == 1 {
        (b1.propagate)()
        (b2.propagate)()
      }
    },
    backward: fn(diff) {
      counter.val -= 1
      cumul.val += diff
      if counter.val == 0 {
        (b1.backward)(cumul.val * b2.value)
        (b2.backward)(cumul.val * b1.value)
      }
    },
  }
}

///|
test "Backward differentiation 后向微分" {
  let diff_x = Ref::{ val: 0.0 }
  let diff_y = Ref::{ val: 0.0 }
  let x = Backward::variable(10.0, diff_x)
  let y = Backward::variable(100.0, diff_y)
  (x * y).backward()
  inspect(diff_x, content="{val: 100}")
  inspect(diff_y, content="{val: 10}")
}

///|
/// x^3 - 10 x^2 + x + 1.0
fn[N : Number] example_newton(x : N) -> N {
  x * x * x + N::constant(-10.0) * x * x + x + N::constant(1.0)
}

///|
test "Newton's method 牛顿迭代法案例" {
  // Using Forward differentiation with abstraction 利用抽象进行前向微分
  let mut x = 1.0
  while true {
    let { value: y, derivative } = example_newton(Forward::variable(x, true))
    if (y / derivative).abs() < 1.0e-9 {
      break
    }
    x -= y / derivative // update x 更新 x
  }
  inspect(x, content="0.37851665401644224")

  // Using Backward differentiation with abstraction 利用抽象进行后向微分
  let derivative = Ref::{ val: 0.0 }
  let mut x = 1.0
  while true {
    let y = example_newton(Backward::variable(x, derivative))
    y.backward()
    if (y.value / derivative.val).abs() < 1.0e-9 {
      break
    }
    x -= y.value / derivative.val // update x 更新 x
    derivative.val = 0.0 // reset the partial derivative 重置偏微分
  }
  inspect(x, content="0.37851665401644224")
}
