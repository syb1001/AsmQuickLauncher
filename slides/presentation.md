title: Basic Example
author:
  name: Jordan Scales, Fan
  email: zhuangchenfan@gmail.com
  url: http://jordanscales.com
output: presentation.html
theme: sudodoki/reveal-cleaver-theme
--

# QUICK LAUNCHER
## 汇编大作业展示·鼠标手势识别+快速启动

--

### What's Quick Launcher

通过识别鼠标轨迹，快速启动程序，并且支持用户来新增、删除、编辑手势以及对应的动作。

<img src="flow.jpg" width="50%">

%[Here's a link](http://google.com).

--

### 基本功能

* 添加手势
* 匹配手势
** 匹配成功，自启动
** 匹配失败，询问是否记住该手势
* 编辑手势
** 删除手势

光说不练假把式 [上demo](http://baidu.com).

--

### Unicode

* 林花謝了春紅 太匆匆
* 胭脂淚 留人醉 幾時重
* Matching Pairs «»‹› “”‘’「」〈〉《》〔〕
* Greek αβγδ εζηθ ικλμ νξοπ ρςτυ φχψω
* currency  ¤ $ ¢ € ₠ £ ¥

--

### A code example

```javascript
// cool looking code
var func = function (arg1) {
    return function (arg2) {
        return "arg1: " + arg1 + "arg2: " + arg2;
    };
};

console.log(func(1)(2)); // result is three
```

And here is some `inline code` to check out.
