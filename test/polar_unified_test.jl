using Fugl
using Fugl: Text

# Test unified polar plot elements
# This tests that PolarLine, PolarScatter, PolarStem return proper AbstractPlotElement types

# Simple test data
theta = range(0, 2π, length=50)
r1 = 1.0f0 .+ 0.3f0 .* sin.(3.0f0 .* theta)
r2 = 0.8f0 .+ 0.2f0 .* cos.(2.0f0 .* theta)
r3 = 0.5f0 .+ 0.4f0 .* sin.(theta)

# Test that constructors return correct types
line_elem = PolarLine(Float32.(r1), Float32.(theta))
scatter_elem = PolarScatter(Float32.(r2), Float32.(theta))
stem_elem = PolarStem(Float32.(r3), Float32.(theta))

println("PolarLine returns: ", typeof(line_elem))
println("PolarScatter returns: ", typeof(scatter_elem))
println("PolarStem returns: ", typeof(stem_elem))

@assert line_elem isa LinePlotElement "PolarLine should return LinePlotElement"
@assert scatter_elem isa ScatterPlotElement "PolarScatter should return ScatterPlotElement"
@assert stem_elem isa StemPlotElement "PolarStem should return StemPlotElement"

# Verify field mapping (x_data = theta, y_data = r)
@assert line_elem.x_data == Float32.(theta) "x_data should contain theta values"
@assert line_elem.y_data == Float32.(r1) "y_data should contain r values"

println("✓ All type checks passed!")
println("✓ Field mapping correct: x_data = theta, y_data = r")

# Dark theme style
dark_style = PolarStyle(
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

polar_state = Ref(PolarState(
    theta_start=Float32(π / 2),  # 0° points up
    theta_direction=:counterclockwise,
    num_angular_lines=12,
    angular_label_format=:degrees
))

function MyApp()
    Column(
        Card(
            "Unified Polar Plot Test - Three Element Types:",
            PolarPlot(
                [
                    PolarLine(
                        Float32.(r1),
                        Float32.(theta),
                        color=Vec4f(0.3, 0.7, 0.9, 1.0),
                        width=2.0f0,
                        label="Line"
                    ),
                    PolarScatter(
                        Float32.(r2),
                        Float32.(theta),
                        fill_color=Vec4f(0.9, 0.5, 0.3, 1.0),
                        border_color=Vec4f(0.2, 0.2, 0.2, 1.0),
                        marker_size=8.0f0,
                        label="Scatter"
                    ),
                    PolarStem(
                        Float32.(r3),
                        Float32.(theta),
                        line_color=Vec4f(0.5, 0.9, 0.4, 1.0),
                        fill_color=Vec4f(0.5, 0.9, 0.4, 1.0),
                        border_color=Vec4f(0.2, 0.2, 0.2, 1.0),
                        label="Stem"
                    )
                ],
                dark_style,
                polar_state[],
                (new_state) -> polar_state[] = new_state
            ),
            style=ContainerStyle(
                background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
                border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
                border_width=1.5f0,
                padding=10.0f0,
                corner_radius=6.0f0
            )
        ),
        Card(
            Fugl.Text("✓ PolarLine → LinePlotElement"),
            style=ContainerStyle(padding=5.0f0)
        ),
        Card(
            Fugl.Text("✓ PolarScatter → ScatterPlotElement"),
            style=ContainerStyle(padding=5.0f0)
        ),
        Card(
            Fugl.Text("✓ PolarStem → StemPlotElement"),
            style=ContainerStyle(padding=5.0f0)
        ),
        Card(
            Fugl.Text("✓ All elements support labels (legend-ready)"),
            style=ContainerStyle(padding=5.0f0)
        ),
        padding=10.0f0
    )
end

Fugl.run(MyApp,
    title="Unified Polar Plot Test",
    window_width_px=900,
    window_height_px=900,
    fps_overlay=true
)
