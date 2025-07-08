using Documenter
using Glance

# Run doctests for Glance.jl

DocMeta.setdocmeta!(Glance, :DocTestSetup, :(using Glance); recursive=true)
Documenter.doctest(Glance)