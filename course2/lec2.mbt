let x: Int = 10
let a: Double = 3.14
let s: String = "Hello"

let 通过编译: Int = x + (a + 0.2).to_int()
// let 不通过编译: String = s + (a + 0.2).to_int() // 删除行首两个斜杠就能看到报错

fn init {
  println(true && false) // 与
  println(false || true) // 或
  println(not(true)) // 非
  println("=====")
  println(-4 / 3) // 整数除法
  println(2147483647 + 1) // 溢出
  println(2147483647L + 1L) // 不溢出
  println(2147483648L.to_int()) // 溢出
  println("=====")
  println(0.1 + 0.2 == 0.3) // 浮点数加法
  println(0.1 + 0.2 - 0.2) // 浮点数加减法
  println("=====")
  println('a'.to_int()) // 字符转数字
  println(Char::from_int(65)) // 数字转字符
  println("=====")
  println((2023, 10, 24).0) // 多元组的访问
  println(("Bob", 3).1) // 多元组的访问
}
