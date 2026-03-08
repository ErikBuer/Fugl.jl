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
    format=Documenter.HTML(
        size_threshold=500 * 1024,  # 500 KiB threshold (default is 200 KiB)
    ),
    sitename="Fugl.jl",
    pages=Any[
        "index.md",
        "running_apps.md",
        "Components"=>Any[
            "Components/container.md",
            "Components/card.md",
            "Components/modal.md",
            "Components/row_col.md",
            "Components/split_container.md",
            "Components/align.md",
            "Components/padding.md",
            "Components/sizing.md",
            "Components/Rotate.md",
            "Components/vline_hline.md",
            "Components/text.md",
            "Components/text_box.md",
            "Components/code_editor.md",
            "Components/dropdown.md",
            "Components/image.md",
            "Components/slider.md",
            "Components/scroll_area.md",
            "Components/text_field.md",
            "Components/formatted_textfield.md",
            "Components/number_field.md",
            "Components/text_button.md",
            "Components/icon_button.md",
            "Components/checkbox.md",
            "Plot"=>Any[
                "Cartesian"=>Any[
                    "Components/plot/cartesian/line_plot.md",
                    "Components/plot/cartesian/legend.md",
                    "Components/plot/cartesian/stem_plot.md",
                    "Components/plot/cartesian/scatter_plot.md",
                    "Components/plot/cartesian/heatmap.md",
                    "Components/plot/cartesian/colorbar.md",
                    "Components/plot/cartesian/plot_style.md",
                    "Components/plot/cartesian/plot_state.md",
                ],
                "Polar"=>Any[
                    "Components/plot/polar/polar_plot.md",
                    "Components/plot/polar/polar_scatter.md",
                    "Components/plot/polar/polar_stem.md",
                    "Components/plot/polar/polar_legend.md",
                ],
            ],
            "Components/table.md",
            "Components/tree.md",
            "Components/keylistener.md",
            "Components/focus.md",
        ],
        "adding_shaders.md",
        "interaction.md",
        "api_reference.md",
    ],
    doctest=true,
)

deploydocs(
    repo="github.com/ErikBuer/Fugl.jl.git",
    push_preview=true,
)