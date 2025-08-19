using Fugl

function colorbar_demo()
    # Create sample data for heatmap
    x_range = range(-2π, 2π, length=20)
    y_range = range(-2π, 2π, length=20)

    x_data = Float32.(collect(x_range))
    y_data = Float32.(collect(y_range))

    # Create 2D function data
    z_data = Float32.([sin(x) * cos(y) for y in y_range, x in x_range])

    # Create main heatmap
    heatmap = HeatmapElement(z_data, x_range=(x_data[1], x_data[end]), y_range=(y_data[1], y_data[end]), colormap=:viridis)
    main_plot = Fugl.Plot([heatmap])

    # Create vertical colorbar for the heatmap
    vertical_colorbar = VerticalColorbar(heatmap)

    # Create horizontal colorbar for the heatmap
    horizontal_colorbar = HorizontalColorbar(heatmap)

    # Create UI layout examples
    ui = Column([
            # Example 1: Plot with vertical colorbar on the right
            IntrinsicRow([
                    main_plot,
                    FixedWidth(Plot([vertical_colorbar], PlotStyle(
                            show_left_axis=true,
                            show_right_axis=true,
                            show_top_axis=true,
                            show_bottom_axis=true,
                            show_x_ticks=false,
                            show_y_ticks=true
                        )), 100.0f0)
                ], spacing=0.0
            ),

            # Example 2: Plot with horizontal colorbar at bottom
            IntrinsicColumn([
                    main_plot,
                    FixedHeight(Plot([horizontal_colorbar], PlotStyle(
                            show_left_axis=true,
                            show_right_axis=true,
                            show_top_axis=true,
                            show_bottom_axis=true,
                            show_x_ticks=true,
                            show_y_ticks=false
                        )), 100.0f0)
                ], spacing=0.0
            ),

            # Example 3: Different colormap with custom styling
            IntrinsicRow([
                    Plot([HeatmapElement(z_data, x_range=(x_data[1], x_data[end]), y_range=(y_data[1], y_data[end]), colormap=:plasma)]),
                    FixedWidth(Plot([VerticalColorbar(:plasma, (-1.0f0, 1.0f0))], PlotStyle(
                            show_left_axis=true,
                            show_right_axis=true,
                            show_top_axis=true,
                            show_bottom_axis=true,
                            show_x_ticks=false,
                            show_y_ticks=true
                        )), 100.0f0)
                ], spacing=0.0
            ),], spacing=0.0, padding=0.0)

    return ui
end

# Run the demo
Fugl.run(colorbar_demo, title="Colorbar Demo", window_width_px=812, window_height_px=812, fps_overlay=true)