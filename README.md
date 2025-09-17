# odin-slang

Odin bindings for [slang shader language](https://github.com/shader-slang/slang). libs and foreign imports are for windows only. PR for other systems are welcome. 

The main COM API is handled, the reflection API bindings is WIP, as the original C API has been deprecated. 

# Running the example

1. Copy `slang/bin/slang.dll` and `slang/bin/slang-glsl.dll` to the root directory.
2. `odin run example` from the root directory. Credits go to [@wrapperup](https://github.com/wrapperup) for making this hot-reloadable example
3. Freely modify `example/triangle.slang` to test things out. The shader will hot-reload.  
