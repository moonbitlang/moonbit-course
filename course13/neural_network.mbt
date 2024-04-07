trait Base  {
  constant(Double) -> Self
  value(Self) -> Double
  op_add(Self, Self) -> Self
  op_neg(Self) -> Self
  op_mul(Self, Self) -> Self
  op_div(Self, Self) -> Self
  exp(Self) -> Self // For computing softmax 用于计算softmax
}

fn reLU[T : Base](t : T) -> T {
  if t.value() < 0.0 {
    T::constant(0.0)
  } else {
    t
  }
}

fn softmax[T : Base](inputs : Array[T]) -> Array[T] {
  let n = inputs.length()
  let outputs : Array[T] = Array::make(n, T::constant(0.0))
  let mut sum = T::constant(0.0)
  for i = 0; i < n; i = i + 1 {
    sum = sum + inputs[i].exp()
  }
  for i = 0; i < n; i = i + 1 {
    outputs[i] = inputs[i].exp() / sum
  }
  outputs
}

fn input2hidden[T : Base](inputs : Array[Double], param : Array[Array[T]]) ->
     Array[T] {
  let outputs : Array[T] = Array::make(param.length(), T::constant(0.0))
  for output = 0; output < param.length(); output = output + 1 {
    for input = 0; input < inputs.length(); input = input + 1 {
      outputs[output] = outputs[output] + T::constant(inputs[input]) * param[output][input]
    }
    outputs[output] = outputs[output] + param[output][inputs.length()] // constant 常数
      |> reLU
  }
  outputs
}

fn hidden2output[T : Base](inputs : Array[T], param : Array[Array[T]]) ->
     Array[T] {
  let outputs : Array[T] = Array::make(param.length(), T::constant(0.0))
  for output = 0; output < param.length(); output = output + 1 {
    for input = 0; input < inputs.length(); input = input + 1 {
      outputs[output] = outputs[output] + inputs[input] * param[output][input]
    }
    outputs[output] = outputs[output] + param[output][inputs.length()] // constant 常数
  }
  outputs |> softmax
}

fn compute[T : Base](inputs : Array[Double], param_hidden : Array[Array[T]],
        param_output : Array[Array[T]]) -> Array[T] {
  inputs |> input2hidden(param_hidden) |> hidden2output(param_output)
}

trait Log  {
  log(Self) -> Self // For computing cross entropy 用于计算交叉熵
}

fn cross_entropy[T : Base + Log](inputs : Array[T], expected : Int) -> T {
  -inputs[expected].log()
}

fn verify[N : Base](result : Array[N], expected : Int) -> Bool {
  match expected {
    0 =>
      return result[0].value() > result[1].value() && result[0].value() > result[2].value()
    1 =>
      return result[1].value() > result[0].value() && result[1].value() > result[2].value()
    2 =>
      return result[2].value() > result[1].value() && result[2].value() > result[0].value()
    _ => abort("")
  }
}

fn diff(inputs : Array[Double], expected : Int,
        param_hidden : Array[Array[Backward]],
        param_output : Array[Array[Backward]]) -> Unit {
  let result = compute(inputs, param_hidden, param_output)
    |> cross_entropy(expected)
  result.backward(1.0)
}

fn update(params : Array[Array[Double]], diff : Array[Array[Double]],
        step : Double) -> Unit {
  for i = 0; i < params.length(); i = i + 1 {
    for j = 0; j < params[i].length(); j = j + 1 {
      params[i][j] = params[i][j] - step * diff[i][j]
    }
  }
}

fn train(param_hidden : Array[Array[Double]],
        param_output : Array[Array[Double]], step : Double) -> Unit {
  let diff_hidden : Array[Array[Double]] = Array::make(
    param_hidden.length(),
    Array::default(),
  )
  for i = 0; i < diff_hidden.length(); i = i + 1 {
    diff_hidden[i] = Array::make(param_hidden[i].length(), 0.0)
  }
  let backward_hidden : Array[Array[Backward]] = Array::make(
    param_hidden.length(),
    Array::default(),
  )
  for i = 0; i < param_hidden.length(); i = i + 1 {
    backward_hidden[i] = Array::make(
      param_hidden[i].length(),
      Backward::constant(0.0),
    )
    for j = 0; j < param_hidden[i].length(); j = j + 1 {
      backward_hidden[i][j] = {
        value: param_hidden[i][j],
        propagate: fn() {  },
        backward: fn { d => diff_hidden[i][j] = diff_hidden[i][j] + d },
      }
    }
  }
  let diff_output : Array[Array[Double]] = Array::make(
    param_output.length(),
    Array::default(),
  )
  for i = 0; i < diff_output.length(); i = i + 1 {
    diff_output[i] = Array::make(param_output[i].length(), 0.0)
  }
  let backward_output : Array[Array[Backward]] = Array::make(
    param_output.length(),
    Array::default(),
  )
  for i = 0; i < param_output.length(); i = i + 1 {
    backward_output[i] = Array::make(
      param_output[i].length(),
      Backward::constant(0.0),
    )
    for j = 0; j < param_output[i].length(); j = j + 1 {
      backward_output[i][j] = {
        value: param_output[i][j],
        propagate: fn() {  },
        backward: fn { d => diff_output[i][j] = diff_output[i][j] + d },
      }
    }
  }
  for i = 0; i < train_dataset.length(); i = i + 1 {
    diff(
      train_dataset[i].input,
      train_dataset[i].expected,
      backward_hidden,
      backward_output,
    )
  }
  update(param_hidden, diff_hidden, step)
  update(param_output, diff_output, step)
}

fn main {
  let hidden_layer : Array[Array[Double]] = Array::make(4, Array::default())
  for i = 0; i < hidden_layer.length(); i = i + 1 {
    hidden_layer[i] = Array::make(5, 0.2)
  }
  let output_layer : Array[Array[Double]] = Array::make(3, Array::default())
  for i = 0; i < output_layer.length(); i = i + 1 {
    output_layer[i] = Array::make(5, 0.2)
  }
  let learning_rate = 0.002
  let decay_rate = -0.005
  for i = 0; i < 400; i = i + 1 {
    train(
      hidden_layer,
      output_layer,
      learning_rate * Base::exp(decay_rate * i.to_double()), // Exponential decay 指数衰减
    )
  }
  for i = 0, correct = 0, wrong = 0; i < test_dataset.length(); {
    let result = compute(test_dataset[i].input, hidden_layer, output_layer)
    if verify(result, test_dataset[i].expected) {
      continue i + 1,
        correct + 1,
        wrong
    } else {
      continue i + 1,
        correct,
        wrong + 1
    }
  } else {
    println("correct \(correct) wrong \(wrong)")
  }
}

// Backward differentiation 后向微分

pub struct Backward {
  value : Double
  propagate : () -> Unit // Topogical sort 拓扑排序
  backward : (Double) -> Unit
}

fn Backward::constant(d : Double) -> Backward {
  { value: d, propagate: fn() {  }, backward: fn { _ => () } }
}

fn Backward::var(value : Double, diff : Ref[Double]) -> Backward {
  { value, propagate: fn() {  }, backward: fn { d => diff.val = diff.val + d } }
}

fn Backward::backward(b : Backward, d : Double) -> Unit {
  (b.propagate)()
  (b.backward)(d)
}

fn Backward::value(backward : Backward) -> Double {
  backward.value
}

fn Backward::op_add(b1 : Backward, b2 : Backward) -> Backward {
  let counter = { val: 0 }
  let cumul = { val: 0.0 }
  {
    value: b1.value + b2.value,
    propagate: fn() {
      counter.val = counter.val + 1
      if counter.val == 1 {
        (b1.propagate)()
        (b2.propagate)()
      }
    },
    backward: fn(diff) {
      counter.val = counter.val - 1
      cumul.val = cumul.val + diff
      if counter.val == 0 {
        (b1.backward)(cumul.val)
        (b2.backward)(cumul.val)
      }
    },
  }
}

fn Backward::op_neg(b : Backward) -> Backward {
  let counter = { val: 0 }
  let cumul = { val: 0.0 }
  {
    value: -b.value,
    propagate: fn() {
      counter.val = counter.val + 1
      if counter.val == 1 {
        (b.propagate)()
      }
    },
    backward: fn(diff) {
      counter.val = counter.val - 1
      cumul.val = cumul.val + diff
      if counter.val == 0 {
        (b.backward)(-cumul.val)
      }
    },
  }
}

fn Backward::op_mul(b1 : Backward, b2 : Backward) -> Backward {
  let counter = { val: 0 }
  let cumul = { val: 0.0 }
  {
    value: b1.value * b2.value,
    propagate: fn() {
      counter.val = counter.val + 1
      if counter.val == 1 {
        (b1.propagate)()
        (b2.propagate)()
      }
    },
    backward: fn(diff) {
      counter.val = counter.val - 1
      cumul.val = cumul.val + diff
      if counter.val == 0 {
        (b1.backward)(cumul.val * b2.value)
        (b2.backward)(cumul.val * b1.value)
      }
    },
  }
}

fn Backward::op_div(b1 : Backward, b2 : Backward) -> Backward {
  let counter = { val: 0 }
  let cumul = { val: 0.0 }
  {
    value: b1.value / b2.value,
    propagate: fn() {
      counter.val = counter.val + 1
      if counter.val == 1 {
        (b1.propagate)()
        (b2.propagate)()
      }
    },
    backward: fn(diff) {
      counter.val = counter.val - 1
      cumul.val = cumul.val + diff
      if counter.val == 0 {
        (b1.backward)(cumul.val / b2.value)
        (b2.backward)(-cumul.val * b1.value / b2.value / b2.value)
      }
    },
  }
}

fn Backward::exp(b : Backward) -> Backward {
  let b_exp = Base::exp(b.value)
  let counter = { val: 0 }
  let cumul = { val: 0.0 }
  {
    value: b_exp,
    propagate: fn() {
      counter.val = counter.val + 1
      if counter.val == 1 {
        (b.propagate)()
      }
    },
    backward: fn(diff) {
      counter.val = counter.val - 1
      cumul.val = cumul.val + diff
      if counter.val == 0 {
        (b.backward)(cumul.val * b_exp)
      }
    },
  }
}

fn Backward::log(b : Backward) -> Backward {
  let counter = { val: 0 }
  let cumul = { val: 0.0 }
  {
    value: Log::log(b.value),
    propagate: fn() {
      counter.val = counter.val + 1
      if counter.val == 1 {
        (b.propagate)()
      }
    },
    backward: fn(diff) {
      counter.val = counter.val - 1
      cumul.val = cumul.val + diff
      if counter.val == 0 {
        (b.backward)(cumul.val / b.value)
      }
    },
  }
}

// Implementation for Double 浮点数的实现

fn Base::constant(d : Double) -> Double {
  d
}

fn Base::value(d : Double) -> Double {
  d
}

fn Base::exp(x : Double) -> Double {
  x |> exp_ffi
}

fn exp_ffi(x : Double) -> Double = "math" "exp"

fn Log::log(x : Double) -> Double {
  x |> log_ffi
}

fn log_ffi(x : Double) -> Double = "math" "log"

/// IRIS 鸢尾花
struct Data {
  input : Array[Double]
  expected : Int
}

let train_dataset : Array[Data] = [
  { input: [5.1, 3.5, 1.4, 0.2], expected: 0 },
  { input: [4.9, 3.0, 1.4, 0.2], expected: 0 },
  { input: [4.7, 3.2, 1.3, 0.2], expected: 0 },
  { input: [4.6, 3.1, 1.5, 0.2], expected: 0 },
  { input: [5.0, 3.6, 1.4, 0.2], expected: 0 },
  { input: [5.4, 3.9, 1.7, 0.4], expected: 0 },
  { input: [4.6, 3.4, 1.4, 0.3], expected: 0 },
  { input: [5.4, 3.7, 1.5, 0.2], expected: 0 },
  { input: [4.8, 3.4, 1.6, 0.2], expected: 0 },
  { input: [4.8, 3.0, 1.4, 0.1], expected: 0 },
  { input: [4.3, 3.0, 1.1, 0.1], expected: 0 },
  { input: [5.8, 4.0, 1.2, 0.2], expected: 0 },
  { input: [5.7, 4.4, 1.5, 0.4], expected: 0 },
  { input: [5.4, 3.9, 1.3, 0.4], expected: 0 },
  { input: [5.1, 3.5, 1.4, 0.3], expected: 0 },
  { input: [5.7, 3.8, 1.7, 0.3], expected: 0 },
  { input: [5.1, 3.8, 1.5, 0.3], expected: 0 },
  { input: [7.0, 3.2, 4.7, 1.4], expected: 1 },
  { input: [6.1, 2.8, 4.7, 1.2], expected: 1 },
  { input: [6.4, 2.9, 4.3, 1.3], expected: 1 },
  { input: [6.6, 3.0, 4.4, 1.4], expected: 1 },
  { input: [6.8, 2.8, 4.8, 1.4], expected: 1 },
  { input: [6.7, 3.0, 5.0, 1.7], expected: 1 },
  { input: [6.4, 2.7, 5.3, 1.9], expected: 2 },
  { input: [6.8, 3.0, 5.5, 2.1], expected: 2 },
  { input: [5.7, 2.5, 5.0, 2.0], expected: 2 },
  { input: [5.8, 2.8, 5.1, 2.4], expected: 2 },
  { input: [6.0, 2.9, 4.5, 1.5], expected: 1 },
  { input: [5.7, 2.6, 3.5, 1.0], expected: 1 },
  { input: [5.5, 2.4, 3.8, 1.1], expected: 1 },
  { input: [5.5, 2.4, 3.7, 1.0], expected: 1 },
  { input: [5.8, 2.7, 3.9, 1.2], expected: 1 },
  { input: [6.0, 2.7, 5.1, 1.6], expected: 1 },
  { input: [5.4, 3.0, 4.5, 1.5], expected: 1 },
  { input: [6.0, 3.4, 4.5, 1.6], expected: 1 },
  { input: [6.7, 3.1, 4.7, 1.5], expected: 1 },
  { input: [6.3, 2.3, 4.4, 1.3], expected: 1 },
  { input: [5.6, 3.0, 4.1, 1.3], expected: 1 },
  { input: [5.5, 2.5, 4.0, 1.3], expected: 1 },
  { input: [5.5, 2.6, 4.4, 1.2], expected: 1 },
  { input: [6.1, 3.0, 4.6, 1.4], expected: 1 },
  { input: [5.8, 2.6, 4.0, 1.2], expected: 1 },
  { input: [5.0, 2.3, 3.3, 1.0], expected: 1 },
  { input: [5.6, 2.7, 4.2, 1.3], expected: 1 },
  { input: [5.7, 3.0, 4.2, 1.2], expected: 1 },
  { input: [5.0, 3.4, 1.5, 0.2], expected: 0 },
  { input: [4.4, 2.9, 1.4, 0.2], expected: 0 },
  { input: [4.9, 3.1, 1.5, 0.1], expected: 0 },
  { input: [5.7, 2.9, 4.2, 1.3], expected: 1 },
  { input: [6.2, 2.9, 4.3, 1.3], expected: 1 },
  { input: [5.1, 2.5, 3.0, 1.1], expected: 1 },
  { input: [5.7, 2.8, 4.1, 1.3], expected: 1 },
  { input: [6.3, 3.3, 6.0, 2.5], expected: 2 },
  { input: [5.8, 2.7, 5.1, 1.9], expected: 2 },
  { input: [7.1, 3.0, 5.9, 2.1], expected: 2 },
  { input: [6.3, 2.9, 5.6, 1.8], expected: 2 },
  { input: [6.5, 3.0, 5.8, 2.2], expected: 2 },
  { input: [7.6, 3.0, 6.6, 2.1], expected: 2 },
  { input: [4.9, 2.5, 4.5, 1.7], expected: 2 },
  { input: [7.3, 2.9, 6.3, 1.8], expected: 2 },
  { input: [6.7, 2.5, 5.8, 1.8], expected: 2 },
  { input: [7.2, 3.6, 6.1, 2.5], expected: 2 },
  { input: [6.5, 3.2, 5.1, 2.0], expected: 2 },
  { input: [6.4, 3.2, 5.3, 2.3], expected: 2 },
  { input: [6.5, 3.0, 5.5, 1.8], expected: 2 },
  { input: [7.7, 3.8, 6.7, 2.2], expected: 2 },
  { input: [7.7, 2.6, 6.9, 2.3], expected: 2 },
  { input: [6.0, 2.2, 5.0, 1.5], expected: 2 },
]

let test_dataset : Array[Data] = [
  { input: [5.4, 3.4, 1.7, 0.2], expected: 0 },
  { input: [5.1, 3.7, 1.5, 0.4], expected: 0 },
  { input: [4.6, 3.6, 1.0, 0.2], expected: 0 },
  { input: [5.1, 3.3, 1.7, 0.5], expected: 0 },
  { input: [4.8, 3.4, 1.9, 0.2], expected: 0 },
  { input: [5.0, 3.0, 1.6, 0.2], expected: 0 },
  { input: [5.0, 3.4, 1.6, 0.4], expected: 0 },
  { input: [5.2, 3.5, 1.5, 0.2], expected: 0 },
  { input: [5.2, 3.4, 1.4, 0.2], expected: 0 },
  { input: [4.7, 3.2, 1.6, 0.2], expected: 0 },
  { input: [4.8, 3.1, 1.6, 0.2], expected: 0 },
  { input: [5.4, 3.4, 1.5, 0.4], expected: 0 },
  { input: [5.2, 4.1, 1.5, 0.1], expected: 0 },
  { input: [5.5, 4.2, 1.4, 0.2], expected: 0 },
  { input: [4.9, 3.1, 1.5, 0.1], expected: 0 },
  { input: [5.0, 3.2, 1.2, 0.2], expected: 0 },
  { input: [5.5, 3.5, 1.3, 0.2], expected: 0 },
  { input: [4.9, 3.1, 1.5, 0.1], expected: 0 },
  { input: [4.4, 3.0, 1.3, 0.2], expected: 0 },
  { input: [5.1, 3.4, 1.5, 0.2], expected: 0 },
  { input: [5.0, 3.5, 1.3, 0.3], expected: 0 },
  { input: [4.5, 2.3, 1.3, 0.3], expected: 0 },
  { input: [4.4, 3.2, 1.3, 0.2], expected: 0 },
  { input: [5.0, 3.5, 1.6, 0.6], expected: 0 },
  { input: [5.1, 3.8, 1.9, 0.4], expected: 0 },
  { input: [4.8, 3.0, 1.4, 0.3], expected: 0 },
  { input: [5.1, 3.8, 1.6, 0.2], expected: 0 },
  { input: [4.6, 3.2, 1.4, 0.2], expected: 0 },
  { input: [5.3, 3.7, 1.5, 0.2], expected: 0 },
  { input: [5.0, 3.3, 1.4, 0.2], expected: 0 },
  { input: [6.4, 3.2, 4.5, 1.5], expected: 1 },
  { input: [6.9, 3.1, 4.9, 1.5], expected: 1 },
  { input: [5.5, 2.3, 4.0, 1.3], expected: 1 },
  { input: [6.5, 2.8, 4.6, 1.5], expected: 1 },
  { input: [5.7, 2.8, 4.5, 1.3], expected: 1 },
  { input: [6.3, 3.3, 4.7, 1.6], expected: 1 },
  { input: [4.9, 2.4, 3.3, 1.0], expected: 1 },
  { input: [6.6, 2.9, 4.6, 1.3], expected: 1 },
  { input: [5.2, 2.7, 3.9, 1.4], expected: 1 },
  { input: [5.0, 2.0, 3.5, 1.0], expected: 1 },
  { input: [5.9, 3.0, 4.2, 1.5], expected: 1 },
  { input: [6.0, 2.2, 4.0, 1.0], expected: 1 },
  { input: [6.1, 2.9, 4.7, 1.4], expected: 1 },
  { input: [5.6, 2.9, 3.6, 1.3], expected: 1 },
  { input: [6.7, 3.1, 4.4, 1.4], expected: 1 },
  { input: [5.6, 3.0, 4.5, 1.5], expected: 1 },
  { input: [5.8, 2.7, 4.1, 1.0], expected: 1 },
  { input: [6.2, 2.2, 4.5, 1.5], expected: 1 },
  { input: [5.6, 2.5, 3.9, 1.1], expected: 1 },
  { input: [5.9, 3.2, 4.8, 1.8], expected: 1 },
  { input: [6.1, 2.8, 4.0, 1.3], expected: 1 },
  { input: [6.3, 2.5, 4.9, 1.5], expected: 1 },
  { input: [6.9, 3.2, 5.7, 2.3], expected: 2 },
  { input: [5.6, 2.8, 4.9, 2.0], expected: 2 },
  { input: [7.7, 2.8, 6.7, 2.0], expected: 2 },
  { input: [6.3, 2.7, 4.9, 1.8], expected: 2 },
  { input: [6.7, 3.3, 5.7, 2.1], expected: 2 },
  { input: [7.2, 3.2, 6.0, 1.8], expected: 2 },
  { input: [6.2, 2.8, 4.8, 1.8], expected: 2 },
  { input: [6.1, 3.0, 4.9, 1.8], expected: 2 },
  { input: [6.4, 2.8, 5.6, 2.1], expected: 2 },
  { input: [7.2, 3.0, 5.8, 1.6], expected: 2 },
  { input: [7.4, 2.8, 6.1, 1.9], expected: 2 },
  { input: [7.9, 3.8, 6.4, 2.0], expected: 2 },
  { input: [6.4, 2.8, 5.6, 2.2], expected: 2 },
  { input: [6.3, 2.8, 5.1, 1.5], expected: 2 },
  { input: [6.1, 2.6, 5.6, 1.4], expected: 2 },
  { input: [7.7, 3.0, 6.1, 2.3], expected: 2 },
  { input: [6.3, 3.4, 5.6, 2.4], expected: 2 },
  { input: [6.4, 3.1, 5.5, 1.8], expected: 2 },
  { input: [6.0, 3.0, 4.8, 1.8], expected: 2 },
  { input: [6.9, 3.1, 5.4, 2.1], expected: 2 },
  { input: [6.7, 3.1, 5.6, 2.4], expected: 2 },
  { input: [6.9, 3.1, 5.1, 2.3], expected: 2 },
  { input: [5.8, 2.7, 5.1, 1.9], expected: 2 },
  { input: [6.8, 3.2, 5.9, 2.3], expected: 2 },
  { input: [6.7, 3.3, 5.7, 2.5], expected: 2 },
  { input: [6.7, 3.0, 5.2, 2.3], expected: 2 },
  { input: [6.3, 2.5, 5.0, 1.9], expected: 2 },
  { input: [6.5, 3.0, 5.2, 2.0], expected: 2 },
  { input: [6.2, 3.4, 5.4, 2.3], expected: 2 },
  { input: [5.9, 3.0, 5.1, 1.8], expected: 2 },
]
