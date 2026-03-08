# Interactive Polar Legend

Click on legend items to toggle visibility of polar plot elements.

``` @example InteractiveLegendPolar
using Fugl

# Dark theme polar plot style
style = Ref(PolarStyle(
    background_color=Vec4f(0.08, 0.10, 0.14, 1.0),
    show_radial_grid=true,
    show_angular_grid=true,
    radial_grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    angular_grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    show_outer_circle=true,
    outer_circle_color=Vec4f(0.9, 0.9, 0.95, 1.0),
    outer_circle_width=2.0f0,
    label_color=Vec4f(0.9, 0.9, 0.95, 1.0)
))

# Create sample polar data
theta = range(0, 2π, length=100)

# Rose curve: r = cos(3θ)
rose_r = abs.(cos.(3 .* theta)) .|> Float32

# Spiral: r = θ / 2π
spiral_r = (theta ./ (2π)) .|> Float32

# Circle
circle_r = fill(0.5f0, length(theta))

# Store plot elements in a Ref for dynamic updates
elements = Ref([
    PolarLine(
        rose_r,
        collect(Float32, theta);
        color=Vec4f(0.8, 0.2, 0.2, 1.0),
        width=2.0f0,
        label="Rose"
    ),
    PolarLine(
        spiral_r,
        collect(Float32, theta);
        color=Vec4f(0.2, 0.4, 0.8, 1.0),
        width=2.0f0,
        label="Spiral"
    ),
    PolarLine(
        circle_r,
        collect(Float32, theta);
        color=Vec4f(0.2, 0.8, 0.2, 1.0),
        width=2.0f0,
        line_style=DASH,
        label="Circle"
    )
])

# Plot state
plot_state = Ref(PolarState())

function app()
    Card(
        "Interactive Polar Legend Demo",
        IntrinsicRow([
            PolarPlot(
                elements[],
                style[],
                plot_state[],
                (new_state) -> plot_state[] = new_state
            ),
            FixedWidth(
                Container(
                    Legend(
                        elements[],
                        text_style=TextStyle(size_px=12, color=Vec4f(0.9, 0.9, 0.95, 1.0)),
                        on_click=(idx) -> begin
                            # Toggle muted state of clicked element
                            old_elem = elements[][idx]
                            new_elem = toggle_mute(old_elem)

                            # Update elements array
                            new_elements = copy(elements[])
                            new_elements[idx] = new_elem
                            elements[] = new_elements
                        end
                    ),
                    style=ContainerStyle(
                        background_color=Vec4f(0.18, 0.18, 0.22, 0.95),
                        border_color=Vec4f(0.3, 0.3, 0.35, 1.0),
                        border_width=2.0f0,
                        padding=10.0f0,
                        corner_radius=8.0f0
                    )
                ),
                200.0f0
            )
        ]),
        style=ContainerStyle(
            background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
            border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
            border_width=1.5f0,
            padding=12.0f0,
            corner_radius=6.0f0
        ),
        title_style=TextStyle(size_px=18, color=Vec4f(0.9, 0.9, 0.95, 1.0))
    )
end

screenshot(app, "InteractivePlarLegend.png", 812, 812);
nothing #hide
```

![Polar Legend](InteractivePlarLegend.png)