push!(LOAD_PATH, "../src/")

using Documenter

# Running `julia --project docs/make.jl` can be very slow locally.
# To speed it up during development, one can use make_local.jl instead.
# The code below checks wether its being called from make_local.jl or not.
const LOCAL = get(ENV, "LOCAL", "false") == "true"

if LOCAL
    include("../src/Glance.jl")
    using .Glance
else
    using Glance
    ENV["GKSwstype"] = "100"
end

DocMeta.setdocmeta!(Glance, :DocTestSetup, :(using Glance); recursive=true)


makedocs(
    modules=[Glance],
    format=Documenter.HTML(),
    sitename="Glance.jl",
    pages=Any[
        "index.md",
        "Components"=>Any[
            "Components/container.md",
            "Components/layout.md",
            "Components/text.md",
            "Components/text_box.md",
            "Components/image.md",
            "Components/slider.md",
            "Components/text_button.md",
        ],
        "interaction.md",
        "api_reference.md",
    ],
    doctest=true,
)

deploydocs(
    repo="github.com/ErikBuer/Glance.jl.git",
    push_preview=true,
)