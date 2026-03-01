# OpenGL tutorials in Julia

The code in this directory closely follows the tutorials at
https://open.gl/, but they are written in Julia rather than C++.  They
are not replacements for the (excellent) exposition of those
tutorials, but they show how to write the same code in Julia.

The file names match the corresponding page (e.g.,
`"context_creation.jl"`), sometimes with different versions (`1`, `2`,
etc.) representing either different portions of the chapter, or, in
some cases, alternative approaches to the same task.  This directory
also contains answers to the exercises posed at the end of some
chapters; if you are trying to learn OpenGL, you should try to
complete the exercises first on your own and look at the answer only
if you get stuck.

The earliest files are deliberately low-level, using just
[GLFW](https://github.com/JuliaGL/GLFW.jl) and
[ModernGL](https://github.com/JuliaGL/ModernGL.jl)---they are
essentially direct, minimal translations of the C++ code. Starting
with `drawing_polygons2.jl`, we illustrate the use of
[GLWindow](https://github.com/JuliaGL/GLWindow.jl) for simplifying
window/context creation.  Starting with `drawing_polygons5.jl`, more
of the "julian" conveniences available in GLAbstraction are
introduced.

Some of the files require external resources; it's recommended that
you first `include("downloads.jl")` to download all the relevant
files.

There is a `run_all.jl` file in tutorial, you can try it out to go through the whole tutorial. It will run `download.jl` first to download necessary files.

The sequence of tutorials is:

- [`context_creation.jl`](context_creation.jl)
- [`drawing_polygons1.jl`](drawing_polygons1.jl)
- [`drawing_polygons2.jl`](drawing_polygons2.jl)
- [`drawing_polygons3.jl`](drawing_polygons3.jl)
- [`drawing_polygons4.jl`](drawing_polygons4.jl)
- [`drawing_polygons5.jl`](drawing_polygons5.jl)
- exercise files for drawing polygons
- [`textures1.jl`](textures1.jl)
- [`textures2.jl`](textures2.jl)
- exercise files for textures
- [`transformations1.jl`](transformations1.jl)
- [`transformations2.jl`](transformations2.jl)
- exercise files for transformations
- [`depth_stencils1.jl`](depth_stencils1.jl)
