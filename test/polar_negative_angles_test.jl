using Fugl
using Fugl: Text

# Test that polar plots handle negative angles seamlessly
# Common use case: plotting from -π to π

# Create data with negative angles
theta = range(-π, π, length=100)
#theta = mod2pi.(theta)
r = 1.0f0 .+ 0.5f0 .* cos.(3.0f0 .* theta)

# Dark theme styles
dark_card_style = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

dark_title_style = TextStyle(
    size_px=18,
    color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

polar_style = PolarStyle(
    background_color=Vec4f(0.08, 0.10, 0.14, 1.0),
    show_radial_grid=true,
    show_angular_grid=true,
    radial_grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    angular_grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    show_outer_circle=true,
    outer_circle_color=Vec4f(0.9, 0.9, 0.95, 1.0),
    outer_circle_width=2.0f0,
    label_color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

polar_state = PolarState(
    theta_start=0.0f0,
    theta_direction=:counterclockwise,
    num_angular_lines=12,
    angular_label_format=:degrees
)

function MyApp()
    Card(
        "Negative Angles Test: -π to π",
        PolarPlot(
            [
                PolarLine(
                    Float32.(r),
                    Float32.(theta),
                    color=Vec4f(0.4, 0.6, 0.9, 1.0),
                    width=2.5f0
                )
            ],
            polar_style,
            polar_state
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

Fugl.run(MyApp)