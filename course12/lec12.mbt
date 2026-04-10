///|
/// Symbolic differentiation 符号微分
enum Symbol {
  Constant(Double)
  Var(Int)
  Add(Symbol, Symbol)
  Sub(Symbol, Symbol)
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
impl Add for Symbol with add(f1 : Symbol, f2 : Symbol) -> Symbol {
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
impl Sub for Symbol with sub(f1 : Symbol, f2 : Symbol) -> Symbol {
  match (f1, f2) {
    (a, Constant(0.0)) => a
    (Constant(a), Constant(b)) => Constant(a - b)
    _ => Sub(f1, f2)
  }
}

///|
impl Mul for Symbol with mul(f1 : Symbol, f2 : Symbol) -> Symbol {
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
fn Symbol::compute(self : Symbol, input : Array[Double]) -> Double {
  match self {
    Constant(d) => d
    Var(i) => input[i] // get value following index 根据下标取值
    Add(f1, f2) => f1.compute(input) + f2.compute(input)
    Sub(f1, f2) => f1.compute(input) - f2.compute(input)
    Mul(f1, f2) => f1.compute(input) * f2.compute(input)
  }
}

///|
/// val is the index of the variable to be differentiated 
/// val代表当前微分的变量
fn Symbol::differentiate(self : Symbol, val : Int) -> Symbol {
  match self {
    Constant(_) => Constant(0.0)
    Var(i) => if i == val { Constant(1.0) } else { Constant(0.0) } // determine if is the variable to be differentiated 根据下标判断是否为微分对象
    Add(f1, f2) => f1.differentiate(val) + f2.differentiate(val)
    Sub(f1, f2) => f1.differentiate(val) - f2.differentiate(val)
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

///|
/// Forward differentiation: dual number 前向微分，对偶数
struct Dual {
  value : Double
  derivative : Double
} derive(Show)

///|
/// diff: weather differentiate this variable
/// diff：是否对当前变量求偏微分
fn Dual::variable(d : Double, diff : Bool) -> Dual {
  { value: d, derivative: if diff { 1.0 } else { 0.0 } }
}

///|
impl Add for Dual with add(f : Dual, g : Dual) -> Dual {
  { value: f.value + g.value, derivative: f.derivative + g.derivative } // f' + g',,,
}

///|
impl Mul for Dual with mul(f : Dual, g : Dual) -> Dual {
  {
    value: f.value * g.value,
    derivative: f.value * g.derivative + g.value * f.derivative, // f * g' + g * f',,,
  }
}

///|
fn Dual::constant(d : Double) -> Dual {
  { value: d, derivative: 0.0 }
}

///|
fn Dual::value(f : Dual) -> Double {
  f.value
}

// 后向

///|
type Var = Int

///|
struct Edge {
  parent : Var
  w : Double
} derive(Show)

///|
struct Node {
  v : Double
  mut grad : Double
  parents : Array[Edge]
} derive(Show)

///|
struct Tape {
  nodes : Array[Node]
} derive(Show)

///|
fn Tape::new() -> Tape {
  { nodes: [] }
}

///|
fn Tape::val(self : Tape, id : Var) -> Double {
  self.nodes[id].v
}

///|
fn Tape::grad(self : Tape, id : Var) -> Double {
  self.nodes[id].grad
}

///|
fn Tape::zero_grad(self : Tape) -> Unit {
  for i in 0..<self.nodes.length() {
    self.nodes[i].grad = 0.0
  }
}

///|
fn Tape::push(self : Tape, v : Double, parents : Array[Edge]) -> Var {
  let id = self.nodes.length()
  self.nodes.push({ v, grad: 0.0, parents })
  id
}

///|
fn Tape::input(self : Tape, v : Double) -> Var {
  self.push(v, [])
}

///|
fn Tape::add(self : Tape, a : Var, b : Var) -> Var {
  let va = self.val(a)
  let vb = self.val(b)
  self.push(va + vb, [{ parent: a, w: 1.0 }, { parent: b, w: 1.0 }])
}

///|
fn Tape::sub(self : Tape, a : Var, b : Var) -> Var {
  let va = self.val(a)
  let vb = self.val(b)
  self.push(va - vb, [{ parent: a, w: 1.0 }, { parent: b, w: -1.0 }])
}

///|
fn Tape::mul(self : Tape, a : Var, b : Var) -> Var {
  let va = self.val(a)
  let vb = self.val(b)
  // d(a*b)/da = b, d(a*b)/db = a
  self.push(va * vb, [{ parent: a, w: vb }, { parent: b, w: va }])
}

///|
fn Tape::div(self : Tape, a : Var, b : Var) -> Var {
  let va = self.val(a)
  let vb = self.val(b)
  // d(a/b)/da = 1/b, d(a/b)/db = -a/b^2
  self.push(va / vb, [
    { parent: a, w: 1.0 / vb },
    { parent: b, w: -(va / (vb * vb)) },
  ])
}

///|
fn Tape::relu(self : Tape, a : Var) -> Var {
  let va = self.val(a)
  if va > 0.0 {
    self.push(va, [{ parent: a, w: 1.0 }])
  } else {
    self.push(0.0, [{ parent: a, w: 0.0 }])
  }
}

///|
fn Tape::pow(self : Tape, a : Var, p : Double) -> Var {
  let va = self.val(a)
  // y = a^p
  // dy/da = p*a^(p-1)
  let y = @math.pow(va, p)
  let w = p * @math.pow(va, p - 1.0)
  self.push(y, [{ parent: a, w }])
}

///|
fn Tape::exp(self : Tape, a : Var) -> Var {
  let va = self.val(a)
  let y = @math.exp(va)
  self.push(y, [{ parent: a, w: y }])
}

///|
fn Tape::sin(self : Tape, a : Var) -> Var {
  let va = self.val(a)
  self.push(@math.sin(va), [{ parent: a, w: @math.cos(va) }])
}

///|
fn Tape::cos(self : Tape, a : Var) -> Var {
  let va = self.val(a)
  self.push(@math.cos(va), [{ parent: a, w: -@math.sin(va) }])
}

///|
fn Tape::backward(self : Tape, out : Var) -> Unit {
  self.zero_grad()
  self.nodes[out].grad = 1.0
  // 逆序遍历：把每个节点的梯度分发给它的父节点
  for i = self.nodes.length() - 1; i >= 0; i = i - 1 {
    let g = self.nodes[i].grad
    for e in self.nodes[i].parents {
      self.nodes[e.parent].grad += g * e.w
    }
  }
}

///|
fn example_newton(x : Dual) -> Dual {
  x * x * x + Dual::constant(-10.0) * x * x + x + Dual::constant(1.0)
}

///|
fn example_newton_bw(t : Tape, x : Var) -> Var {
  let t1 = t.mul(t.mul(x, x), x)
  let t2 = t.mul(t.input(-10.0), t.mul(x, x))
  t.add(t.add(t.add(t1, t2), x), t.input(1.0))
}

///|
test "Newton's method 牛顿迭代法案例" {
  // Using Forward differentiation with abstraction 利用抽象进行前向微分
  let mut x = 1.0
  while true {
    let { value: y, derivative } = example_newton(Dual::variable(x, true))
    if (y / derivative).abs() < 1.0e-9 {
      break
    }
    x -= y / derivative // update x 更新 x
  }
  inspect(x, content="0.37851665401644224")

  // Using Backward differentiation with abstraction 利用抽象进行后向微分
  let mut x = 1.0
  while true {
    let tape = Tape::new()
    let x_var = tape.input(x)
    let y = example_newton_bw(tape, x_var)
    tape.backward(y)
    if (tape.val(y) / tape.grad(x_var)).abs() < 1.0e-9 {
      break
    }
    x -= tape.val(y) / tape.grad(x_var) // update x 更新 x
  }
  inspect(
    x,
    content=(
      #|0.37851665401644224
    ),
  )
}
