using Fugl

# Build a sample load sweep in normalized impedance z = r + jx.
r_data = Float32[0.2, 0.35, 0.5, 0.8, 1.0, 1.4, 2.1, 3.0]
x_data = Float32[-1.8, -1.2, -0.8, -0.3, 0.0, 0.4, 0.9, 1.4]

trace1 = SmithTraceFromNormalizedImpedance(
    r_data,
    x_data;
    label="Z sweep",
    color=Vec4f(0.03, 0.52, 0.90, 1.0),
    width=2.6f0,
    show_markers=true,
    marker_size=5.5f0
)

# Example admittance trajectory.
g_data = Float32[0.1, 0.2, 0.35, 0.5, 0.8, 1.2, 1.6]
b_data = Float32[1.8, 1.2, 0.8, 0.3, -0.2, -0.8, -1.2]
trace2 = SmithTraceFromNormalizedAdmittance(
    g_data,
    b_data;
    label="Y sweep",
    color=Vec4f(0.88, 0.30, 0.05, 1.0),
    width=2.0f0,
    show_markers=false
)

smith_style = SmithStyle(
    background_color=Vec4f(0.08, 0.10, 0.14, 1.0),
    grid_color=Vec4f(0.34, 0.36, 0.42, 1.0),
    axis_color=Vec4f(0.62, 0.66, 0.76, 1.0),
    outer_circle_color=Vec4f(0.90, 0.93, 0.98, 1.0),
    label_color=Vec4f(0.90, 0.93, 0.98, 1.0),
    marker_fill_color=Vec4f(0.93, 0.95, 0.98, 1.0),
    marker_border_color=Vec4f(0.05, 0.16, 0.25, 1.0),
    show_admittance_grid=false,
    padding=42.0f0,
    anti_aliasing_width=1.1f0,
    label_size_points=14
)

function MyApp()
    Card(
        "Smith Plot Demo",
        SmithPlot([trace1, trace2], smith_style),
        style=ContainerStyle(
            background_color=Vec4f(0.12, 0.13, 0.16, 1.0),
            border_color=Vec4f(0.25, 0.27, 0.32, 1.0),
            border_width=1.2f0,
            padding=10.0f0,
            corner_radius=6.0f0
        ),
        title_style=TextStyle(size_points=18, color=Vec4f(0.92, 0.95, 0.99, 1.0))
    )
end

Fugl.run(
    MyApp,
    title="Smith Plot Demo",
    window_width_points=920,
    window_height_points=860,
    fps_overlay=true
)
