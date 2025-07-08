using Documenter
using Fugl

# Run doctests for Fugl.jl

DocMeta.setdocmeta!(Fugl, :DocTestSetup, :(using Fugl); recursive=true)
Documenter.doctest(Fugl)