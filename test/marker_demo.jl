using Fugl
using Fugl: Text, SOLID, DASH, DOT, DASHDOT, CIRCLE, TRIANGLE, RECTANGLE

function main()
    # Demo showcasing marker types with border and fill colors
    x_data = Float32[1, 2, 3, 4, 5]
    y_data = Float32[2, 3, 1, 4, 2]

    # Create scatter plots with different marker types
    circle_scatter = ScatterPlotElement(
        y_data;
        x_data=x_data,
        fill_color=Vec4{Float32}(1.0, 0.2, 0.2, 1.0),
        border_color=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),
        marker_size=6.0f0,
        border_width=2.0f0,
        marker_type=CIRCLE,
        label="Circles"
    )

    triangle_scatter = ScatterPlotElement(
        y_data .+ 1;
        x_data=x_data,
        fill_color=Vec4{Float32}(0.2, 1.0, 0.2, 1.0),
        border_color=Vec4{Float32}(0.0, 0.5, 0.0, 1.0),
        marker_size=6.0f0,
        border_width=2.0f0,
        marker_type=TRIANGLE,
        label="Triangles"
    )

    rectangle_scatter = ScatterPlotElement(
        y_data .+ 2;
        x_data=x_data,
        fill_color=Vec4{Float32}(0.2, 0.2, 1.0, 1.0),
        border_color=Vec4{Float32}(0.0, 0.0, 0.5, 1.0),
        marker_size=6.0f0,
        border_width=2.0f0,
        marker_type=RECTANGLE,
        label="Rectangles"
    )

    # Create stem plots with different marker types
    stem_circles = StemPlotElement(
        [1.5, 2.5, 1.0, 3.0, 2.0];
        x_data=[6, 7, 8, 9, 10],
        line_color=Vec4{Float32}(0.5, 0.5, 0.5, 1.0),  # Gray stems
        fill_color=Vec4{Float32}(1.0, 0.2, 0.2, 1.0),  # Red fill
        border_color=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),  # Black border
        line_width=3.0f0,
        marker_size=6.0f0,
        border_width=2.0f0,
        marker_type=CIRCLE,
        baseline=0.0f0,
        label="Stem Circles"
    )

    stem_rectangles = StemPlotElement(
        [2.0, 3.0, 1.5, 3.5, 2.5];
        x_data=[6, 7, 8, 9, 10],
        line_color=Vec4{Float32}(0.3, 0.7, 0.3, 1.0),  # Green stems
        fill_color=Vec4{Float32}(0.2, 1.0, 0.2, 1.0),  # Green fill
        border_color=Vec4{Float32}(0.0, 0.5, 0.0, 1.0),  # Dark green border
        line_width=3.0f0,
        marker_size=6.0f0,
        border_width=1.5f0,
        marker_type=RECTANGLE,
        baseline=0.0f0,  # Start from Y=0 axis
        label="Stem Rectangles"
    )

    function MyApp()
        IntrinsicColumn([
                IntrinsicHeight(Container(Text("Marker Demo - Scatter and Stem Plots with Custom Shapes"))),

                # Plot with all marker types
                Container(
                    Plot(
                        [circle_scatter, triangle_scatter, rectangle_scatter,
                            stem_circles, stem_rectangles],
                        PlotStyle(
                            background_color=Vec4{Float32}(0.98, 0.98, 0.98, 1.0),
                            grid_color=Vec4{Float32}(0.85, 0.85, 0.85, 1.0),
                            axis_color=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),
                            padding_px=30.0f0,
                            show_grid=true,
                            show_axes=true,
                            anti_aliasing_width=1.5f0
                        )
                    )
                )
            ], padding=0.0f0, spacing=0.0f0)
    end

    Fugl.run(MyApp, title="Marker Demo", window_width_px=1200, window_height_px=800, fps_overlay=true)
end

main()
