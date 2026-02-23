

```bash
julia --project=/home/ubuntu-desktop/repos/GLFW.jl -e "using JuliaC; JuliaC.main(ARGS)" -- --output-exe testapp --bundle build --trim=safe --experimental test/GlfwTrim.jl/GlfwTrim.jl
```