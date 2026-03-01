include("downloads.jl")
using GLFW
tutorials = readdir(dirname(@__FILE__))
filter!(tutorials) do file
    endswith(file, ".jl") &&
    basename(file) != "downloads.jl" &&
    basename(file) != "run_all.jl"
end
for tutorial in tutorials
    GLFW.Init()
    println("Now showing: ", tutorial)
    include(tutorial)
    GLFW.Terminate() # clean up gl context
end
