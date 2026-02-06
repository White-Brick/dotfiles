# 全局规则
- 始终使用简体中文回复

## CMakeLists.txt规范
- 生成`compile_command.json`文件(`set(CMAKE_EXPORT_COMPILE_COMMANDS ON)`)，并生成软链接
- 使用brew安装的LLVM作为C++编译器：`set(CMAKE_CXX_COMPILER "/opt/homebrew/opt/llvm/bin/clang++")`

## 语言和风格
- 直接回答问题，不要客套话
- 代码注释也用中文

## 代码规范
- 变量名用驼峰命名（camelCase）
- 函数名用动词开头（如 getUserById）

## 工作习惯
- 修改代码前先阅读相关文件
- 不确定时先问，不要猜测
- 每次只做最小必要的修改
