# Modern Programming Concepts: Tuples, Structures, and Enumerated Types

Hello everyone, welcome to the open course on modern programming concepts brought to you by the IDEA's Digital Infrastructure Innovation. Today's topic is tuples, structures, and enumerated types. In a nutshell, we will be exploring how to customize data structures in MoonBit.

## Review: Tuples

First, review the fundamental data type in MoonBit introduced in course 2: Tuples.

A MoonBit tuple is a composite of data which have different types with a fixed length. In comparison, lists are collections of data which have the same type with arbitrary lengths. For example, the length of the list below is not fixed, but the values stored must all be of the character type. In the previous lesson, we didn't discuss why `Cons` is named `Cons`. It is an abbreviation for `Construct`.

```moonbit
Cons('H', Cons('i', Cons('!', Nil)))
```

The definition of tuples is represented by expressions enclosed in parentheses and separated by commas. The types are also specified using the same syntax, as in the definition of personal identity information here: `("Bob", 2023, 10, 24): (String, Int, Int, Int)`.

Tuple members are accessed by indexes, starting from 0 on the left. For example, `(2023, 10, 24).0 == 2023`.

# Cartesian Product

You may be familiar with the concept of the Cartesian product. The Cartesian product of two sets is a set where all elements are ordered pairs formed by the elements of the original two sets. For example, the Cartesian product of the set of card suits and the numbers 1 to 52 forms all possible ordered pairs of suits and numbers. 

{ ♥️ ♦️ ♠️ ♣️ } $\times \{ n \in \mathbb{N} | 1 \leq n \leq 52 \}$ 

Tuples, on the other hand, go beyond the Cartesian product of two sets; they represent the Cartesian product of multiple sets, making them more accurately termed as ordered sets. Consequently, tuples are also known as product types. You might wonder if there are sum types alongside product types. We will introduce sum types and explore the concepts of **zero** and **one** later.

## Structures

The problem is that it is hard to understand the data represented by tuples. For example, `(String, Int)` – does it represent a person's name and age, or a person's name and phone number, or perhaps address and email?

Structures allow us to assign **names** to the data, both to the entire type and to each field individually. For instance:

- `struct PersonalInfo { name: String; age: Int }`
- `struct ContactInfo { name: String; telephone: Int }`
- `struct AddressInfo { address: String; postal: Int }`

We can clearly understand the information about the data and the meaning of each corresponding field by names.

The syntax of defining a structure is `struct <struct_name> { <field_name>: <type> ; ... }`. For example: `struct PersonalInfo { name: String; age: Int }`. As we have mentioned, the semicolons can be omitted when the fields are on separate lines.

Definitions of the values of a structure are enclosed in braces, with each field assigned a value: `<field_name>: <value>`; each field assignment is followed by a comma. For instance: `let info: PersonalInfo = { name: "Moonbit", age: 1, }`. Note the comma after each value. It can be omitted if the last comma is directly followed by the closing brace without a newline. The order of fields does not matter, for example, `{ age: 1, name: "Moonbit" }`. If two structures happen to have exactly the same field names and types, they cannot be distinguished solely by the defined values. In such cases, we can differentiate them by adding a type declaration after the structure's value, such as `: A`.

Accessing the fields of a structure is similar to tuples – by using the field name to retrieve the corresponding data, for example, `.age` to retrieve the field `age`. When creating a new structure based on an existing one, redeclaring each field can be tedious, especially if the original structure is large. For convenience, MoonBit also provides a feature to update only specific fields. We can simply indicate the base structure with `.. <original_structure>` before the definition of the structure values, and then only declare the fields that have been modified. See the example below.

```moonbit
let new_info = { .. old_info, age: 2, }
let other_info = { .. old_info, name: "Hello", }
```

# Relationship Between Tuples and Structures

You may notice that tuples and structures seem quite similar. In fact, a structure and a tuple composed of the same types are isomorphic. Isomorphism, in this context, means there exists a one-to-one mapping between two sets. If there are mappings `f: (A) -> B` and `g: (B) -> A` between sets `A` and `B`, such that for any `a` and `b`, it satisfies `g(f(a)) == a` and `f(g(b)) == b`, as shown in the diagram below, then these two sets are isomorphic.

![Isomorphism Diagram](../pics/isomorphism.drawio.png)

For example, `PersonalInfo` and `(String, Int)` are isomorphic, as we can establish the following pair of mappings:

```moonbit
fn f(info: PersonalInfo) -> (String, Int) { (info.name, info.age) }

fn g(pair: (String, Int)) -> PersonalInfo { { name: pair.0, age: pair.1, }}
```

Feel free to verify this. Similarly, `PersonalInfo` is isomorphic to `(Int, String)`. You can try defining the corresponding mappings yourself.

The key difference between tuples and structures lies in their compatibility. Tuples are *structural*, meaning they are compatible as long as the structure is the same – each field type corresponds one-to-one. For example, a function successfully accepts a tuple here. 

```moonbit
fn accept(tuple: (Int, String)) -> Bool {
  true
}
let accepted: Bool = accept((1, "Yes"))
```

On the other hand, structures are *nominal*, meaning compatibility is based on the type name, and the internal order can be rearranged. In the first example, even though the structures are identical, the function cannot accept the structure because the type names are different. In the second example, the function can accept it because the types are the same even if the order of the fields is different.

```moonbit
struct A { val : Int ; other: Int }
struct B { val : Int ; other: Int }
fn accept(a: A) -> Bool {
  true
}
let not_accepted: Bool = accept(({ val : 1, other : 2 }: B)) // DO NOT COMPILE
let accepted: Bool = accept(({other: 2, val: 1}: A))
```

## Pattern Matching

Pattern matching is another way to access tuples and structures.

```moonbit
fn head_opt(list: List[Int]) -> Option[Int] {
  match list {
    Nil => None
    Cons(head, tail) => Some(head)
  }
}

fn get_or_else(option_int: Option[Int], default: Int) -> Int {
  match option_int {
    None => default
    Some(value) => value
  }
}
```

We have previously used pattern matching to inspect the structure of lists and Options. For instance, using `Nil` and `Cons` to match lists; `None` and `Some` to match Options. In fact, pattern matching can match values (logical values, numbers, characters, strings) as well as constructors. 


```moonbit
fn is_zero(i: Int) -> Bool {
  match i {
    0 => true
    1 | 2 | 3 => false
    _ => false
  }
}
```

In the examples above, we matched numbers. Here we use the pipe symbol (the 'or' pattern) to simultaneously match multiple possible values. The underscore (_) is the wildcard to match all remaining cases. We can nest patterns in constructors, or bind corresponding structures with identifiers.

```moonbit
fn contains_zero(l: List[Int]) -> Bool {
  match l {
    Nil => false
    Cons(0, _) => true
    Cons(_, tl) => contains_zero(tl)
  }
}
```

In this example, the first `Cons` uses the number 0 to match lists starting with 0, and the second `Cons` uses a wildcard and an identifier `tl` to match remaining lists while binding the sublist to the identifier `tl` for further processing. The value of the current list is discarded by the wildcard.

Pattern matching for tuples and structures is just like for constructions. 

```moonbit
fn first(pair: (Int, Int)) -> Int {
  match pair {
    (first, second) => first
  }
}

fn baby_name(info: PersonalInfo) -> Option[String] {
  match info {
    { age: 0, .. } => None
    { name, age } => Some(name)
  }
}
```

Tuples' patterns are just like their definitions, enclosed in parentheses and separated by commas. Make sure the length of the matched tuple is correct. Structure patterns are enclosed in braces and separated by commas. We have additional pattern forms to make pattern matching more flexible:

* Explicitly match some specific values, such as `age: 0` to match the data with specific values. 
* Use another identifier to bind a field, such as `age: my_age`. This is useful when you don't want to use the field name as an identifier.
* Omit remaining fields with `..` at the end.

Here is another example for better understanding how to use nested patterns. The `zip` function combines two lists into a new list of pairs like a zipper. The length of the resulting list is the minimum of the lengths of the input lists. Given the lists [1, 2, 3] and [a, b, c, d], the zipped list would be (1, a) (2, b) (3, c).

```moonbit
fn zip(l1: List[Int], l2: List[Char]) -> List[(Int, Char)] {
  match (l1, l2) {
    (Cons(hd, tl), Cons(hd2, tl2)) => Cons((hd, hd2), zip(tl, tl2))
    _ => Nil
  }
}
```

We define our function with pattern matching. Here, we match a pairs by constructing a tuple and then match the nested tuple pattern, effectively matching both lists simultaneously. If either of the input lists is empty, the result is an empty list. When both lists are non-empty, we get a non-empty result. The first item of the result is a tuple of the two values we take from the inputs, followed by the zipped result of the sublists of both lists. Note that the order of pattern matching is top-down. (If a wildcard is placed at the top, the subsequent patterns will never be matched, and the code will never run. The good news is that MoonBit can detect this and provide warnings. These warnings are advisory and won't prevent compilation, so it's crucial to pay attention to the issues panel in your IDE.)

Lastly, pattern matching is not limited to `match`; it can also be used in data binding. In local definitions, we can use pattern matching expressions to bind corresponding substructures to identifiers. It's essential to note that if value comparison occurs at this point and the match fails, the program will encounter a runtime error, leading to program termination.

## Enumerated Types

Now, let's delve into the enumerated types.

Think about this, how should we represent the union of several possibilities? For example, how do we define a type that represents the set of days from Monday to Sunday? How about defining a type for the outcomes of a coin toss – heads or tails? What about a type to represent the results of integer arithmetic operations, such as a successful result, overflow, or division by zero?

The answer is enumerated types. Enumerated types allow us to define data structures that represent different cases. For example, we define a collection of seven days of the week here and the outcomes of a coin toss.

```moonbit
enum DaysOfWeek {
  Monday; Tuesday; Wednesday; Thursday; Friday; Saturday; Sunday
}

enum Coin {
  Head
  Tail
}
```

The construction of an enumerated type is as follows:

```moonbit
enum <type_name> { <variant>; }
```

Here, each possible variant is a constructor. For instance, `let monday = Monday`, where `Monday` defines the day of the week as Monday. Different enumerated types may cause conflicts because they might use the same names for some cases. In such cases, we distinguish them by adding `<type>::` in front of the constructor.

Now we need to ask, why do we need enumerated types? Why not just use numbers from one to seven to represent Monday to Sunday? Let's compare the following two functions. 

```moonbit
fn tomorrow(today: Int) -> Int
fn tomorrow(today: DaysOfWeek) -> DaysOfWeek
let tuesday = 1 * 2 // Is this Tuesday?
```

The most significant difference is that functions defined with enumerated types are total functions, while those defined with integers are partial functions. This increases the possibility of users providing incorrect inputs – they might pass -1 or 8, and we have no way to prevent this through the compiler. Another consideration is, what does adding one to a day of the week mean? What is the meaning of multiplying the day of the week by a number? Why is Monday multiplied by two equal to Tuesday? Why is Tuesday divided by two equal to Monday? Enumerated types can distinguish themselves from existing types and better abstraction.

Additionally, enumerated types prevent the representation of irrational data. For instance, when using various services, user identification can be based on either a phone number or an email, both of which are optional but only one is required. If we use a structure with two nullable fields to represent this, there is a risk of both fields being empty or both having data, which is not what we want. Therefore, enumerated types can be used to better restrict the range of reasonable data.

Each variant of an enumerated type can also carry data. For instance, we've seen the enumerated type `Option`. 

```moonbit
enum Option[T] {
    Some(T)
    None
}

enum ComputeResult {
    Success(Int)
    Overflow
    DivideByZero
}
```

To do this, simply enclose parameters with parentheses and separate them by commas after each variant. In the second example, we define the case of successful integer operation, and the value is an integer. Enumerated types correspond to a distinguishable union. What does that mean? First, it is a union of different cases, for example, the set represented by the type `T` for `Some` and the set defined by the singular value `None`. Second, this union is distinguishable because each case has a unique name. Even if there are two cases with the same data type, they are entirely different. Thus, enumerated types are also known as sum types.

## Algebraic Data Types

We've mentioned product types and sum types. Now, let me briefly introduce algebraic data types. It's important to note that this introduction to algebraic data types is quite basic. Please read the references for a deeper understanding.

The terms tuple, structure, and enumerated type, which we discussed earlier, are collectively referred to as algebraic data types. They are called algebraic data types because they construct types through algebraic operations, specifically "sum" and "product", and they exhibit algebraic structures. Recall the properties of regular numbers, such as equality, addition, multiplication, and the facts such that any number multiplied by 1 equals itself, any number plus 0 equals itself, etc. Similarly, algebraic data types exhibit properties such as:

* type equality implying isomorphism
* type multiplication forming product types (tuples or structures)
* type addition forming sum types (enumerated types) 

Here, **Zero** is a type that corresponds to an **empty type**. We can define an empty enumerated type without any cases; such a type has no constructors, and no values can be constructed, making it empty. **One** corresponds to a type with only one element, which we call the **Unit type**, and its value is a zero-tuple.

Let's verify the properties mentioned earlier: any number multiplied by 1 equals itself, and any number plus 0 equals itself.

```moonbit
fn f[T](t: T) -> (T, Unit) { (t, ()) }
fn g[T](pair: (T, Unit)) -> T { pair.0 }
```

In this context, a type `T` multiplied by 1 implies that `(T, Unit)` is isomorphic to `T`. We can establish a set of mappings: it's straightforward to go from `T` to `(T, Unit)` by simply adding the zero-tuple. Conversely, going from `(T, Unit)` to `T` involves ignoring the zero-tuple. You can intuitively find that they are isomorphic. 

```moonbit
enum PlusZero[T] { CaseT(T); CaseZero(Nothing) }

fn f[T](t: PlusZero) -> T {
  match t {
    CaseT(t) => t
    CaseZero(_) => abort("Impossible case, no such value.")
  }
}

fn g[T](t: T) -> PlusZero { CaseT(t) }
```

The property of any type plus zero equals itself means that, for any type, we define an enumerated type `PlusZero`. One case contains a value of type `T`, and the other case contains a value of type `Nothing`. This type is isomorphic to `T`, and we can construct a set of mappings. Starting with `PlusZero`, we use pattern matching to discuss the cases. If the included value is of type `T`, we map it directly to `T`. If the type is `Nothing`, this case will never happen because there are no values of type `Nothing`, so we use `abort` to handle, indicating that the program will terminate. Conversely, we only need to wrap `T` with `CaseT`. It's essential to emphasize that this introduction is quite basic, providing an intuitive feel. Explore further if you are interested.

Here are a few examples. 

```moonbit
enum Coins { Head; Tail }
```

$\texttt{Coins} = 1 + 1 = 2$

```moonbit
enum DaysOfWeek { Monday; Tuesday; ...; }
```

$\texttt{DaysOfWeek} = 1 + 1 + 1 + 1 + 1 + 1 + 1 = 7$

The data type for the coin toss can be considered as 1 + 1, as each case, `Head` and `Tail`, actually represents a set with only one value. Therefore, each case is isomorphic to the Unit type. When combined by the sum type, the `Coin` type becomes 1 + 1 = 2, representing a set with two values, which is isomorphic to any other type with two values. Similarly, `DaysOfWeek` represents a set of seven values, isomorphic to any other type with seven values. 

A more interesting example is `List`, using `List[Int]` as an example. 

$$
\begin{array}{rl}
\texttt{enum} \ \ \texttt{List} & = \texttt{Nil} + \texttt{Int} \times \texttt{List} \\  
& = \texttt{1} + \texttt{Int} \times \texttt{List} \\
& = \texttt{1} + \texttt{Int} \times (\texttt{1} + \texttt{Int} \times \texttt{List} ) \\
& = \texttt{1} + \texttt{Int} \times \texttt{1} + \texttt{Int} \times \texttt{Int} \times \texttt{List} \\
& = \texttt{1} + \texttt{Int} + \texttt{Int} \times \texttt{Int} + \texttt{Int} * \texttt{Int} \times \texttt{Int} + ...
\end{array}
$$

The definition of `List[Int]` tells us that a list of intergers is either an empty list or composed of an integer with a sublist. An empty list is isomorphic to the Unit type, so it can be expressed as `1 + Int * List`. As `List` is recursive, it can be substituted with `1 + Int * 1 + Int * List`. Applying the associative law of multiplication, we get `1 + Int * (1 + Int * List)`. Continuing the substitution and simplification, we find that the set of integer lists is a distinguishable union of a single-value set, an integer set, two integer sets, and even an infinite Cartesian product of integer sets. This corresponds with reality.

## Summary

In this section, we explored various custom data types in MoonBit, including:

- **Tuples:** Fixed-length combinations of different data types.
- **Structures:** Tuples with names to fields for better understanding.
- **Enumerated Types:** Types that represent a distinct set of values, often used to model different cases or options.
  
We also touched upon the concept of algebraic data types, which encompass tuples, structures, and enumerated types, and discussed some basic properties resembling those found in algebra.

For further exploration, we recommend reading Chapter 6 of [Category Theory for Programmers](https://bartoszmilewski.com/2015/01/13/simple-algebraic-data-types/).

You can also experiment with MoonBit: [try.moonbitlang.com/#44a4eb28](https://try.moonbitlang.com/#44a4eb28).
