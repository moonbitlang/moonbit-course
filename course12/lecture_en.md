# Case Study: Automatic Differentiation

Today, we will talk about another case study on automatic differentiation, while avoiding some of the complex mathematical concepts.

Differentiation is an important operation in computer science. In machine learning, neural networks based on gradient descent apply differentiation to find local minima for training. You might be more familiar with solving functions and approximating zeros using Newton's method. Let's briefly review it. Here, we have plotted a function and set the initial value to 1, which is point A on the number axis. We want to find the zero point near it. We calculate point B on the function corresponding to the x-coordinate of this point and find the derivative at the point, which is the slope of the tangent line at that point. By finding the intersection of the tangent line and the x-axis, we get a value that approximates zero. We then repeat the process to find the point corresponding to the function, calculate the derivative, and find the intersection of the tangent line and the x-axis. This way, we can gradually approach zero and get an approximate solution. We will provide the code implementation at the end.

Today, we will look at the following simple combination of functions, involving only addition and multiplication. For example, when calculating 5 times `x0` squared plus ` x1`, if `x0` is 10 and `x1` is 100, we need to calculate the value of the function, 600, the partial derivative with respect to `x0`, 100, and the partial derivative with respect to `x1`, 1.

# Differentiation

There are several ways to differentiate a function. The first method is manual differentiation where we use a piece of paper and a pen as a natural calculator. The drawback is that it's easy to make mistakes with complex expressions and we can't just manually calculate 24 hours a day. The second method is numerical differentiation, where we add a small value (approaching zero) to the point we want to differentiate, calculate the difference, and divide it by the small value. The issue here is that computers cannot accurately represent decimals, and the larger the absolute value, the less accurate it is. Also, we cannot fully solve infinite series. The third method is symbolic differentiation, where we convert the function into an expression tree and then operate on the tree to get the derivative. For example, here the differentiation result of constant 2 multiplied by x will be constant 2. The problem with symbolic differentiation is that the calculation results may not be simplified enough, and there may be redundant calculations. In addition, it's hard to directly use native control flow like conditionals and loops. If we want to define a function to find the larger value, we have to define an operator instead of simply comparing the current values. Lastly, the fourth method is automatic differentiation. Automatic differentiation uses the derivative rules of composite functions to perform calculation and differentiation by combining basic operations, which also aligns with modular thinking. Automatic differentiation is divided into forward and backward differentiation. We will introduce them one by one.

## Symbolic Differentiation

Let's first look at symbolic differentiation. We define expressions using an enum type. An expression can be a constant, a variable indexed starting from zero, or the sum or product of two functions. Here we define simple constructors and overload operators to produce more concise expressions. Finally, in line 15, we use pattern matching to define a method that computes function values based on symbols, with the input being a vector (omitted here). Let's review the derivative rules. If a function is constant, its derivative is 0. If a variable is partially differentiated with respect to itself, the derivative is 1; otherwise, it's 0. The derivative of the sum of two functions is the sum of their derivatives, while the derivative of the product of two functions is the sum of the derivative of each function multiplied by the other function. For example, the derivative of `f * g​` is the derivative of `f` multiplied by `g` plus the derivative of `g` multiplied by `f`. Using these rules, we differentiate our symbols through pattern matching. Since it's partial differentiation, our parameter also includes an index to indicate which variable we are differentiating with respect to.

We use the previous definition to construct our example function. As we can see, the multiplication and addition operations look very natural because MoonBit allows us to overload some operators. After constructing the expression, we differentiate it to get the corresponding expression, as shown in line 7 and then compute the partial derivative based on the input. Without simplification, the derivative expression we obtain might be quite complicated, as shown below.

Of course, we can define some simplification functions or modify the constructors to simplify the functions. For example, we may simplify the result of addition. Adding 0 to any number is still that number, so we can just keep the number; and when adding two numbers, we can simplify them before computing with other variables. Lastly, if there's an integer on the right, we can move it to the left to avoid writing each optimization rule twice.

Similarly, we can simplify multiplication. Multiplying 0 by any number is still 0, multiplying 1 by any number is still the number itself, and we can simplify multiplying two numbers, etc. After such simplifications, we get a more concise result. Of course, our example is relatively simple. In practice, more simplification is needed, such as combining like terms, etc.

## Automatic Differentiation

Now, let's take a look at automatic differentiation. We first define the operations we want to implement through an interface, which includes constant constructor, addition, and multiplication. We also want to get the value of the current computation. With this interface, we can use the native control flow of the language for computation and dynamically generate computation graphs. In the following example, we can choose an expression to compute based on the current value of `y`, and when we differentiate, we differentiate the corresponding expression.

### Forward Differentiation

We will start with forward differentiation. It is relatively straightforward that it directly uses the derivative rules to simultaneously calculate `f(a)` and `f'(a)`. The reason for calculating both of them instead of just the derivative is simple: when differentiating the product of two functions, we need to know the current values of both functions for computation, so we need to compute both the value and the derivative at the same time. Mathematically, this corresponds to the concept of `dual number` in linear algebra. You are encouraged to dive deeper into it if you find it interesting. Let's construct a struct containing dual numbers, with one field being the value of the current node and the other being the derivative of the current node. It is very simple to construct from constants: the value is the constant, and the derivative is zero. It is also very straightforward to get the current value where we just access the corresponding variable. Here we add a helper function. For a variable, besides its value, we also need to determine if it is the variable to differentiate, and if so, its derivative is 1, otherwise, it is 0, as previously explained.

Next, let's define methods for addition and multiplication, using the derivative rules to directly calculate derivatives. For example, the value of the sum of two functions `f` and `g` is the sum of their values, and the derivative is the sum of their derivatives, as shown in line 4. For the product of two functions `f` and `g`, the value is the product of their values, and the derivative is as introduced before: `f * g' + g * f'`. In this way, we directly calculate the derivatives without creating any intermediate data structures.

Finally, we use the previously defined example with conditionals to calculate derivatives. Note that forward differentiation can only compute the derivative with respect to one input parameter at a time, making it suitable for cases where there are more output parameters than input parameters. In neural networks, however, we typically have a large number of input parameters and one output. Therefore, we need to use the backward differentiation introduced next.

### Backward Differentiation

Backward differentiation utilizes the chain rule for calculation. Suppose we have a function `w` of `x, y, z`, etc., and `x, y, z`, etc. are functions of `t`. Then the partial derivative of `w` with respect to `t` is the partial derivative of `w` with respect to `x` times the partial derivative of `x` with respect to `t`, plus the partial derivative of `w` with respect to `y` times the partial derivative of `y` with respect to `t`, plus the partial derivative of `w` with respect to `z` times the partial derivative of `z` with respect to `t`, and so on. For example, for `f(x0, x1) = x0 ^ 2` times `x1`, we can consider `f` as a function of `g` and `h`, where `g` and `h` are `x0 ^ 2` and `x1` respectively. We differentiate each component: the partial derivative of `f` with respect to `g` is `h`;  the partial derivative of `f` with respect to `h` is `g`;  the partial derivative of `g` with respect to `x0` is `2x0`, and the partial derivative of `h` with respect to `x0` is 0. Lastly, we combine them using the chain rule to get the result `2x0x1`. Backward differentiation is the process where we start with the partial derivative of `f` with respect to `f`, followed by calculating the partial derivatives of `f` with respect to the intermediate functions and their partial derivatives with respect to the intermediate functions, until we reach the partial derivatives with respect to the input parameters. This way, by tracing backward and creating the computation graph of `f` in reverse order, we can compute the derivative of each input node. This is suitable for cases where there are more input parameters than output parameters.

Here we demonstrate an implementation in MoonBit. The backward differentiation node consists of the value of the current node and a function named `backward`. The `backward` function uses the accumulated derivatives from the result to the current node (the parameters) to update the derivatives of all parameters that construct the current node. For example, below, we define a node that represents the input. We use a `Ref` to accumulate the derivatives calculated along all paths. When the backward computation process reaches the end, we add the partial derivative of the function with respect to the current variable to the accumulator. This partial derivative is just the partial derivative of one path in the computation graph. As for constants, they have no input parameters, so the `backward` function does nothing.

Next, let's look at addition and multiplication. Suppose the functions `g` and `h` are involved in computation, the current function is `f`, and the final result is `y`, with `x` as a parameter. We've previously mentioned the partial derivatives of `f` with respect to `g` and `h` and will omit them here. For the accumulated partial derivative of `y` with respect to `x`, the partial derivative through the path of `f` and `g` is the partial derivative of `y` with respect to `f` times the partial derivative of `f` with respect to `g` times the partial derivative of `g` with respect to `x`. Here, the partial derivative of `y` with respect to `f` corresponds to the parameter `diff` in the `backward` function. So we can see in line 4 that the parameter we pass to `g` is `diff * 1.0`, which corresponds to the partial derivative of `y` with respect to `f` times the partial derivative of `f` with respect to `g`. We'll pass a similar parameter to `h`. In line 11, according to the derivative rules, the parameter passed to `g` is `diff` times the current value of `h`, and the parameter passed to `h` is `diff` times the current value of `g`.

Lastly, we'll see how to use it. Let's construct two `Ref`s to store the derivatives of `x` and `y`. We'll use two accumulators to create two input nodes with input values of 10 and 100 respectively. After that, we use the previous example to conduct calculations, and after the forward computation is completed, we call the backward function. The parameter 1.0 corresponds to the derivative of `f` with respect to `f`. At this point, the values in both `Ref`s are updated, and we can obtain the derivatives of all input parameters simultaneously.

Now with backward differentiation, we can try to write a neural network. However, due to time constraints, we'll only demonstrate automatic differentiation and Newton's method to approximate zeros. Let's use the interface to define the functions we saw at the beginning.

Then, we'll use Newton's method to find the value. Since there is only one parameter, we'll use forward differentiation. Let's define `x` as the iteration variable with an initial value of 1.0. Since `x` is the variable with respect to which we are differentiating, we'll set the second parameter to be true. Next, we'll define an infinite loop. In line 5, we compute the value and derivative of the function corresponding to `x`. In line 6, if the value divided by the derivative (i.e., the step size we want to approximate) is small enough, it indicates that we are very close to zero, and we terminate the loop. In line 7, if the condition is not met, we update the value of `x` to be the previous value minus the value divided by the derivative and then continue the loop. In this way, we can eventually get an approximate solution.

# Summary

To summarize, in this lecture we introduced the concept of automatic differentiation. We presented symbolic differentiation and two different implementations of automatic differentiation. For students interested in learning more, we recommend the *3Blue1Brown* series on deep learning (including topics like gradient descent, backpropagation algorithms), and try to write your own neural network.


