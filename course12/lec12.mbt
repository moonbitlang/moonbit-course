/// 符号微分
enum Symbol {
  Constant(Double)
  Var(Int)
  Add(Symbol, Symbol)
  Mul(Symbol, Symbol)
} derive(Debug)

fn Symbol::constant(d : Double) -> Symbol {
  Constant(d)
}

fn Symbol::var(i : Int) -> Symbol {
  Var(i)
}

fn Symbol::op_add(f1 : Symbol, f2 : Symbol) -> Symbol {
  // Add(f1, f2)
  // 以下为化简实现
  match (f1, f2) {
    (Constant(0.0), a) => a
    (Constant(a), Constant(b)) => Constant(a * b)
    (a, Constant(_) as const) => const + a
    _ => Add(f1, f2)
  }
}

fn Symbol::op_mul(f1 : Symbol, f2 : Symbol) -> Symbol {
  // Mul(f1,f2)
  // 以下为化简实现
  match (f1, f2) {
    (Constant(0.0), _) => Constant(0.0)
    (Constant(1.0), a) => a
    (Constant(a), Constant(b)) => Constant(a * b)
    (a, Constant(_) as const) => const * a
    _ => Mul(f1, f2)
  }
}

fn compute(self : Symbol, input : Array[Double]) -> Double {
  match self {
    Constant(d) => d
    Var(i) => input[i] // 根据下标取值
    Add(f1, f2) => f1.compute(input) + f2.compute(input)
    Mul(f1, f2) => f1.compute(input) * f2.compute(input)
  }
}

// val代表当前微分的变量
fn differentiate(self : Symbol, val : Int) -> Symbol {
  match self {
    Constant(_) => Constant(0.0)
    Var(i) => if i == val { Constant(1.0) } else { Constant(0.0) } // 根据下标判断是否为微分对象
    Add(f1, f2) => f1.differentiate(val) + f2.differentiate(val)
    Mul(f1, f2) => f1 * f2.differentiate(val) + f1.differentiate(val) * f2
  }
}

fn example() -> Symbol {
  Symbol::constant(5.0) * Symbol::var(0) * Symbol::var(0) + Symbol::var(1)
}

fn init {
  let input = [10.0, 100.0]
  println("符号微分：计算并分别进行偏微分")
  let symbol : Symbol = example()
  debug(symbol.compute(input))
  println("关于x的偏微分表达式树")
  debug(symbol.differentiate(0)) 
  debug(symbol.differentiate(0).compute(input))
  debug(symbol.differentiate(1).compute(input))
  println("======")
}

// 对运算的抽象
trait Number  {
  constant(Double) -> Self
  op_add(Self, Self) -> Self
  op_mul(Self, Self) -> Self
  value(Self) -> Double
}

// 对浮点数实现抽象
fn Number::constant(d : Double) -> Double {
  d
}

fn Number::value(d : Double) -> Double {
  d
}

// 利用原生控制流求最大值
fn max[N : Number](x : N, y : N) -> N {
  if x.value() > y.value() {
    x
  } else {
    y
  }
}
// 线性整流函数
fn relu[N : Number](x : N) -> N {
  max(x, N::constant(0.0))
}

// 前向微分，二元数
struct Forward {
  value : Double
  derivative : Double
} derive(Debug)

fn Forward::constant(d : Double) -> Forward {
  { value: d, derivative: 0.0 }
}

// diff：是否对当前变量求偏微分
fn Forward::var(d : Double, diff : Bool) -> Forward {
  { value: d, derivative: if diff { 1.0 } else { 0.0 } }
}

fn Forward::op_add(f : Forward, g : Forward) -> Forward {
  {
    value: f.value + g.value,
    derivative: f.derivative + g.derivative // f' + g',,,
  }
}

fn Forward::op_mul(f : Forward, g : Forward) -> Forward {
  {
    value: f.value * g.value,
    derivative: f.value * g.derivative + g.value * f.derivative // f * g' + g * f',,,
  }
}

fn Forward::value(f : Forward) -> Double {
  f.value
}

fn init {
  println("利用抽象进行计算值")
  debug(relu(10.0))
  debug(relu(-10.0))
  println("利用抽象进行前向微分")
  debug(relu(Forward::var(10.0, true)))
  debug(relu(Forward::var(-10.0, true)))
  Forward::var(10.0, false) * Forward::var(100.0, true) |> debug // f(x, y) = x * y, 求df/dy(10, 100)
  println("======")
}

// 后向微分
struct Backward {
  value : Double
  backward : (Double) -> Unit // 更新当前路径获得的偏微分
}

fn Backward::constant(d : Double) -> Backward {
  { value: d, backward: fn { _ => () } }
}

fn Backward::var(value : Double, diff : Ref[Double]) -> Backward {
  { value, backward: fn { d => diff.val = diff.val + d } } // 累加偏微分
}

fn Backward::backward(b : Backward, d : Double) {
  (b.backward)(d)
}

fn Backward::value(backward : Backward) -> Double {
  backward.value
}

fn Backward::op_add(b1 : Backward, b2 : Backward) -> Backward {
  {
    value: b1.value + b2.value,
    backward: fn(diff) { b1.backward(diff); b2.backward(diff) },
  }
}

fn Backward::op_mul(b1 : Backward, b2 : Backward) -> Backward {
  {
    value: b1.value * b2.value,
    backward: fn(diff) {
      b1.backward(diff * b2.value)
      b2.backward(diff * b1.value)
    },
  }
}

fn init {
  println("后向微分")
  let diff_x = Ref::{ val: 0.0 }
  let diff_y = Ref::{ val: 0.0 }
  let x = Backward::var(10.0, diff_x)
  let y = Backward::var(100.0, diff_y)
  (x * y).backward(1.0) // df / df = 1
  debug(diff_x)
  debug(diff_y)
  println("======")
}
fn example_newton[N : Number](x : N) -> N {
  x * x * x + N::constant(-10.0) * x * x + x + N::constant(1.0)
}

fn init {
  println("牛顿迭代法案例")
  fn abs(d : Double) -> Double {
    if d >= 0.0 {
      d
    } else {
      -d
    }
  }

  loop Forward::var(1.0, true) { // 初始值
    x => {
      let { value, derivative } = example_newton(x)
      if abs(value / derivative) < 1.0e-9 {
        break x.value // 结束循环，并且将x.value作为整个循环体的值
      }
      continue Forward::var(x.value - value / derivative, true) // 继续循环
    }
  }
  |> debug
}
