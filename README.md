# 现代编程思想

## 课程简介

编程是一门拥有悠久历史的学科，可以追溯到 19 世纪，当时 Ada Lovelace 写出了早期的程序。自此以后，经过一个世纪的演进，编程语言如雨后春笋般涌现，各种编程范式被提出，各行各业都逐渐有了数字化的需求，程序开发规模也愈加庞大。

在这个背景下，我们推出现代编程思想公开课，旨在让更多的人接触编程，了解现代编程思想，并掌握软件开发的要领。

这门课程主要讲授程序设计与实际应用。课程将会介绍多种编程范式，包括函数式编程、命令式编程与面向对象编程等。同时，我们将演示如何使用 MoonBit 编程语言来开发复杂软件项目。

这门课程适合广泛的受众，从编程初学者到有经验的开发者。不需要特定的先决条件，我们将持续打磨课程，提供清晰易懂的内容。

课程将采用多种教学方法，包括公开课录播、实际项目、编程练习和论坛讨论。同时我们还将提供在线 PPT、代码仓库和推荐阅读等学习资源，以支持学生的学习。

授课的示例代码使用[MoonBit 月兔编程语言](https://moonbitlang.cn)，由基础软件中心开发。月兔支持多范式编程，同时提供云原生开发环境支持，可以无需安装额外软件即在浏览器中开发。

## 致谢

本课程参考宾夕法尼亚大学 CIS1200 课程设计

## 课程安排

| 课程 | 主题                                           | 幻灯片                           | 视频                                                                                                                                                                                    | 代码仓库                                             | 推荐阅读                                                                                                                                                                                                                                                                                                                                                        |
| ---- | ---------------------------------------------- | -------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | 课程介绍与程序设计                             | [第一课.pdf](./course1/lec1.pdf) | [课程介绍与程序设计](https://www.bilibili.com/video/BV1ie411971P) | [样例代码](https://try.moonbitlang.cn/#bc2238e7) | |
| 2    | 月兔开发与月兔中的表达式                       | [第二课.pdf](./course2/lec2.pdf) | [2.1：月兔开发环境的准备](https://www.bilibili.com/video/BV1hM411Q7Sg/)，[2.2：月兔中的表达式（上）](https://www.bilibili.com/video/BV1ja4y1Q7Ex/)，[2.3：月兔中的表达式（下）](https://www.bilibili.com/video/BV1384y1X7YS) | [2.2 样例代码](https://try.moonbitlang.cn/#409493da) | [CODING 入门指南](https://coding.net/help/docs/start/new.html), [适合初学者的简单 Git 教程——nulab](https://nulab.com/zh-cn/learn/software-development/git-tutorial/), [“玩转 VS Code”公众号 > 服务 > 基础 及公众号其他内容]，[月兔构建系统教程](https://www.moonbitlang.cn/docs/build-system-tutorial) ，[月兔语法教程](https://www.moonbitlang.cn/docs/syntax) |
| 3    | 函数, 列表与递归                               | [第三课.pdf](./course3/lec3.pdf) | [3.1: 函数与列表](https://www.bilibili.com/video/BV19u4y1N7Qw/)，[3.2：递归与动态规划](https://www.bilibili.com/video/BV1JC4y1m7Tq/) | [函数列表与递归样例代码](https://try.moonbitlang.cn/#d7d75d90)，[斐波那契数列样例代码](https://try.moonbitlang.cn/#8a74316e) | *Software Foundations* 前三章 或 *Programming Language Foundations in Agda* 前三章；《算法导论》第十四章 |
| 4    | 多元组, 结构体，枚举类型                       | [第四课.pdf](./course4/lec4.pdf) | [4: 多元组，结构体，枚举类型](https://www.bilibili.com/video/BV1wG411S7UP/)  | [样例代码](https://try.moonbitlang.cn/#44a4eb28) | *Category Theory for Programmers* 第六章 |
| 5    | 数据类型：树、二叉树、二叉搜索树、AVL树        | [第五课.pdf](./course5/lec5.pdf) | [5.1：树与二叉树](https://www.bilibili.com/video/BV13w411N7K4/) [5.2：二叉搜索树与二叉平衡树](https://www.bilibili.com/video/BV1x64y1j74y) | [5.1 样例代码](https://try.moonbitlang.cn/#1c269c1c)，[5.2 二叉平衡树](https://try.moonbitlang.cn/#5c28cee3)，[5.2 AVL树](https://try.moonbitlang.cn/#dd5b42ff)           | 《算法导论》第十二、十三章  |
| 6    | 泛型与高阶函数                                 | [第六课.pdf](./course6/lec6.pdf) | [6.1：泛型，栈和队列](https://www.bilibili.com/video/BV1Wc411i7RC/) [6.2：高阶函数，列表折叠与映射](https://www.bilibili.com/video/BV16b4y157Bv/) | [6.1 样例代码](https://try.moonbitlang.cn/#76b65766) [6.2 样例代码](https://try.moonbitlang.cn/#de598d69) | *Software Foundations* 第四章 或 *Programming Language Foundations in Agda* 第十章      |
| 7    | 命令式编程：命令，可变数据结构，循环           | [第七课.pdf](./course7/lec7.pdf) | [7.1：命令式编程](https://www.bilibili.com/video/BV1MQ4y137oY/) [7.2：循环](https://www.bilibili.com/video/BV1UC4y1S7qk/) | [7.1 引用不透明](https://try.moonbitlang.cn/#3da0cc0d) [7.1 可变数据结构](https://try.moonbitlang.cn/#9d3b72c1) [7.2 样例代码](https://try.moonbitlang.cn/#1e8ed769) | |
| 8    | 队列：可变数据实现                             | [第八课.pdf](./course8/lec8.pdf) | [8: 队列：可变数据实现](https://www.bilibili.com/video/BV1Vc41187Bf/) | [循环队列（整数）](https://try.moonbitlang.cn/#01572acd) [链表](https://try.moonbitlang.cn/#10c929e4) | |
| 9    | 接口                                           | [第九课.pdf](./course9/lec9.pdf) | [9: 接口](https://www.bilibili.com/video/BV1m5411i7sD/) | [接口的定义与使用](https://try.moonbitlang.cn/#084eb0c9) [方法的定义与使用](https://try.moonbitlang.cn/#09955138) [表的简易实现](https://try.moonbitlang.cn/#9e4dabbf) | |
| 10   | 哈希表与闭包                                   | [第十课.pdf](./course10/lec10.pdf) | [10.1：哈希表：直接寻址](https://www.bilibili.com/video/BV1bV411X74b/) [10.2：哈希表：开放寻址与闭包](https://www.bilibili.com/video/BV1g64y1P7nq) | [10 哈希表](https://try.moonbitlang.cn/#c7b8f2b8) | 《算法导论》第十一章、《算法》第3.4节 |
| 11   | 案例：语法解析器与Tagless Final                | [第十一课.pdf](./course11/lec11.pdf) | [11.1：词法分析器](https://www.bilibili.com/video/BV18y421a7H7/) [11.2：语法分析器](https://www.bilibili.com/video/BV1Nv42117qq/) | [11 语法解析器与Tagless Final](https://try.moonbitlang.cn/#b7f0b9b3) | 调度场算法 斯坦福CS143 第1-8课 或 《编译原理》前五章 或 《现代编译原理》前三章 |
| 12   | 案例：自动微分                                 | [第十二课.pdf](./course12/lec12.pdf) | [12：自动微分](https://www.bilibili.com/video/BV1QJ4m1s7xA/) | [12 自动微分 样例代码](https://try.moonbitlang.cn/#5f9a520a) | [3Blue1Brown 深度学习](https://space.bilibili.com/88461692/channel/seriesdetail?sid=1528929) |
| 13   | 案例：神经网络                                 | [第十三课.pdf](./course13/lec13.pdf) | [13：神经网络](https://www.bilibili.com/video/BV1XZ421a7Cs/) | [13 神经网络 样例代码]() | [3Blue1Brown 深度学习](https://space.bilibili.com/88461692/channel/seriesdetail?sid=1528929) |
| 14   | 案例：栈式虚拟机                               | [第十四课.pdf](./course14/lec14.pdf) | [14：堆栈虚拟机 上](https://www.bilibili.com/video/BV1bq421w7Mi/) [14.2：堆栈虚拟机 下](https://www.bilibili.com/video/BV1gt421J7FJ/) | [14 堆栈虚拟机 样例代码]() |  |

## 开发环境准备

- [VSCode 下载地址](https://code.visualstudio.com/Download)
- [VSCodium 下载地址](https://mirrors.cernet.edu.cn/list/VSCodium)（可以选择其中一所大学的镜像站进行下载）
- [腾讯云 Coding](https://coding.net/)
- [开发模板](https://github.com/peter-jerry-ye/moonbit-template)（`https://github.com/peter-jerry-ye/moonbit-template.git`）
- [课后练习](https://github.com/moonbit/MPI-exercise)（`https://github.com/moonbit/MPI-exercise.git`）

## 学习社群

### Bilibili

欢迎大家关注我们的 B 站帐号：[MoonBit 月兔](https://space.bilibili.com/1453436642)，我们课程的视频都会存放于此（✅ 一键三连 ❌ 下次一定）。

### MoonBit 月兔开发者论坛

欢迎大家加入我们的[MoonBit 月兔开发者论坛](https://taolun.moonbitlang.cn/c/15-category/15)。在 MoonBit 月兔开发者论坛，我们欢迎来自各个领域的开发者、技术爱好者和学习者。这里是一个充满创意、共享知识和互相帮助的社区。

## 版权声明

### 课程文本

MoonBit Course © 2024 by DII, International Digital Economy Academy is licensed under Attribution-NonCommercial-NoDerivatives 4.0 International 

### 样例代码

Copyright 2024 DII, International Digital Economy Academy

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.