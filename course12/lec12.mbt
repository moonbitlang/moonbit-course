/// Symbolic differentiation 符号微分
enum Symbol {
  Constant(Double)
  Var(Int)
  Add(Symbol, Symbol)
  Mul(Symbol, Symbol)
} derive(Debug, Show)

fn Symbol::constant(d : Double) -> Symbol {
  Constant(d)
}

fn Symbol::var(i : Int) -> Symbol {
  Var(i)
}

fn Symbol::op_add(f1 : Symbol, f2 : Symbol) -> Symbol {
  // Add(f1, f2) // Without simplification 无化简实现
  // With simplification 以下为化简实现
  match (f1, f2) {
    (Constant(0.0), a) => a
    (Constant(a), Constant(b)) => Constant(a * b)
    (a, Constant(_) as const) => const + a
    _ => Add(f1, f2)
  }
}

fn Symbol::op_mul(f1 : Symbol, f2 : Symbol) -> Symbol {
  // Mul(f1,f2) // Without simplification 无化简实现
  // With simplification 以下为化简实现
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
    Var(i) => input[i] // get value following index 根据下标取值
    Add(f1, f2) => f1.compute(input) + f2.compute(input)
    Mul(f1, f2) => f1.compute(input) * f2.compute(input)
  }
}

// val is the index of the variable to be differentiated 
// val代表当前微分的变量
fn differentiate(self : Symbol, val : Int) -> Symbol {
  match self {
    Constant(_) => Constant(0.0)
    Var(i) => if i == val { Constant(1.0) } else { Constant(0.0) } // determine if is the variable to be differentiated 根据下标判断是否为微分对象
    Add(f1, f2) => f1.differentiate(val) + f2.differentiate(val)
    Mul(f1, f2) => f1 * f2.differentiate(val) + f1.differentiate(val) * f2
  }
}

fn example() -> Symbol {
  Symbol::constant(5.0) * Symbol::var(0) * Symbol::var(0) + Symbol::var(1)
}

test "Symbolic differentiation 符号微分" {
  let input = [10.0, 100.0]
  let symbol : Symbol = example()
  @assertion.assert_eq(symbol.compute(input), 600.0)?
  // Expression of df/dx 关于x的偏微分表达式树
  inspect(symbol.differentiate(0), ~content="Mul(Constant(5.0), Var(0))")?
  @assertion.assert_eq(symbol.differentiate(0).compute(input), 50.0)?
  @assertion.assert_eq(symbol.differentiate(1).compute(input), 1.0)?
}

// Abstraction of computation 对运算的抽象
trait Number  {
  constant(Double) -> Self
  op_add(Self, Self) -> Self
  op_mul(Self, Self) -> Self
  value(Self) -> Double
}

// Implement abstraction for Double 对浮点数实现抽象
fn Number::constant(d : Double) -> Double {
  d
}

fn Number::value(d : Double) -> Double {
  d
}

// Compute max with native control flow 利用原生控制流求最大值
fn max[N : Number](x : N, y : N) -> N {
  if x.value() > y.value() {
    x
  } else {
    y
  }
}
// Rectified linear unit 线性整流函数
fn relu[N : Number](x : N) -> N {
  max(x, N::constant(0.0))
}

// Forward differentiation: dual number 前向微分，二元数
struct Forward {
  value : Double
  derivative : Double
} derive(Debug, Show)

fn Forward::constant(d : Double) -> Forward {
  { value: d, derivative: 0.0 }
}

// diff: weather differentiate this variable
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

test "Forward differentiation 前向微分" {
  // Compute using abstraction 利用抽象进行计算值
  @assertion.assert_eq(relu(10.0), 10.0)?
  @assertion.assert_eq(relu(-10.0), 0.0)?
  // Forward differentiation with abstraction 利用抽象进行前向微分
  inspect(relu(Forward::var(10.0, true)), ~content="{value: 10.0, derivative: 1.0}")?
  inspect(relu(Forward::var(-10.0, true)), ~content="{value: 0.0, derivative: 0.0}")?
  // f(x, y) = x * y => df/dy(10, 100)
  inspect(Forward::var(10.0, false) * Forward::var(100.0, true), ~content="{value: 1000.0, derivative: 10.0}")?
}

// Backward differentiation 后向微分
// Warning : this implementation is not fully correct as it can cause exponential complexity
// 警告：这个实现并不完全正确，可能会导致指数级复杂度的计算
struct Backward {
  value : Double
  backward : (Double) -> Unit // update the partial derivative of the current path 更新当前路径获得的偏微分
} derive(Debug, Show)

fn Backward::constant(d : Double) -> Backward {
  { value: d, backward: fn { _ => () } }
}

fn Backward::var(value : Double, diff : Ref[Double]) -> Backward {
  { value, backward: fn { d => diff.val = diff.val + d } } // accumulate partial derivative 累加偏微分
}

fn Backward::backward(b : Backward, d : Double) -> Unit {
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

test "Backward differentiation 后向微分" {
  let diff_x = Ref::{ val: 0.0 }
  let diff_y = Ref::{ val: 0.0 }
  let x = Backward::var(10.0, diff_x)
  let y = Backward::var(100.0, diff_y)
  (x * y).backward(1.0) // df / df = 1
  inspect(diff_x, ~content="{val: 100.0}")?
  inspect(diff_y, ~content="{val: 10.0}")?
}

fn example_newton[N : Number](x : N) -> N {
  x * x * x + N::constant(-10.0) * x * x + x + N::constant(1.0)
}

test "Newton's method 牛顿迭代法案例" {
  fn abs(d : Double) -> Double {
    if d >= 0.0 {
      d
    } else {
      -d
    }
  }

  (loop Forward::var(1.0, true) { // initial value 初始值
    x => {
      let { value, derivative } = example_newton(x)
      if abs(value / derivative) < 1.0e-9 {
        break x.value // end the loop and have x.value as the value of the loop body 结束循环，并且将x.value作为整个循环体的值
      }
      continue Forward::var(x.value - value / derivative, true) // continue the loop 继续循环
    }
  } |> @assertion.assert_eq(0.37851665401644224))?
}
