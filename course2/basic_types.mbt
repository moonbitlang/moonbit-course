///|
let x : Int = 10

///|
let a : Double = 3.14

///|
let s : String = "Hello"

///| the following code compiles 下方的代码可以编译
let 通过编译 : Int = x + (a + 0.2).to_int()

// code on line 15 does not compile, uncomment (remove the `//`) to see error
// 第15行的代码无法通过编译，取消注释（删除行首的`//`）来查看错误提示
// let 不通过编译: String = s + (a + 0.2).to_int()

///| 
/// The following codes are tested with assertions.
/// If the assertion is failed, the program will fail
/// 下方代码利用断言判断。如果断言未满足，程序将失败
test {
  // logical and 逻辑与
  assert_false(true && false)
  // logical or 逻辑或
  assert_true(false || true)
  // logical not 逻辑否
  assert_false(not(true))

  // division between integers 整数相除
  assert_eq(-1, -4 / 3)
  // integer overflow 整数溢出
  assert_eq(-2147483648, 2147483647 + 1)
  // will not overflow if they were 64 bits integer 利用64位整数则不会溢出
  assert_eq(2147483648L, 2147483647L + 1L)
  // will overflow if convert back to 32 bits integer 如果转回32位整数会溢出
  assert_eq(-2147483648, 2147483648L.to_int())

  // addition of floating point numbers is not accurate 浮点数加法并不精准
  assert_not_eq(0.3, 0.1 + 0.2)
  assert_not_eq(0.1, 0.1 + 0.2 - 0.2)

  // convert char to/from charcode 字符与编码转换
  assert_eq(65, 'A'.to_int())
  assert_eq('A', (65).unsafe_to_char())

  // accessing tuple 多元组访问
  assert_eq(2023, (2023, 10, 24).0)
  assert_eq(3, ("Bob", 3).1)
}
