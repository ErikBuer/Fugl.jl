push!(LOAD_PATH, "../src/")

using Documenter

# Running `julia --project docs/make.jl` can be very slow locally.
# To speed it up during development, one can use make_local.jl instead.
# The code below checks wether its being called from make_local.jl or not.
const LOCAL = get(ENV, "LOCAL", "false") == "true"

if LOCAL
    include("../src/Fugl.jl")
    using .Fugl
else
    using Fugl
    ENV["GKSwstype"] = "100"
end

DocMeta.setdocmeta!(Fugl, :DocTestSetup, :(using Fugl); recursive=true)


makedocs(
    modules=[Fugl],
    format=Documenter.HTML(),
    sitename="Fugl.jl",
    pages=Any[
        "index.md",
        "Components"=>Any[
            "Components/container.md",
            "Components/card.md",
            "Layout"=>Any[
                "Components/layout/row_col.md",
                "Components/layout/split_container.md",
                "Components/layout/align.md",
                "Components/layout/sizing.md",
                "Components/layout/padding.md",
            ],
            "Components/vline_hline.md",
            "Components/text_box.md",
            "Components/code_editor.md",
            "Components/dropdown.md",
            "Components/image.md",
            "Components/slider.md",
            "Components/number_field.md",
            "Components/text_button.md",
            "Components/icon_button.md",
            "Plot"=>Any[
                "Components/plot/01_line_plot.md",
                "Components/plot/02_stem_plot.md",
                "Components/plot/03_scatter_plot.md",
                "Components/plot/04_heatmap.md",
                "Components/plot/05_colorbar.md",
                "Components/plot/06_plot_style.md",
                "Components/plot/07_plot_state.md",
            ],
            "Components/tree.md",
        ],
        "interaction.md",
        "api_reference.md",
    ],
    doctest=true,
)

deploydocs(
    repo="github.com/ErikBuer/Fugl.jl.git",
    push_preview=true,
)