using Fugl

colorbarstate = Ref(PlotState())


function colorbar_debug()
    # Create simple vertical colorbar test
    vertical_colorbar = VerticalColorbar(:viridis, (0.0f0, 100.0f0))
    colorbar_plot = Fugl.Plot([vertical_colorbar],
        PlotStyle(
            show_left_axis=true,
            show_right_axis=true,
            show_top_axis=true,
            show_bottom_axis=true,
            show_x_ticks=false,
            show_y_ticks=true
        ),
        colorbarstate[],
        (state) -> colorbarstate[] = state
    )

    ui = FixedWidth(colorbar_plot, 100.0f0)

    return ui
end

# Run the debug test
Fugl.run(colorbar_debug, title="Colorbar Debug", window_width_px=200, window_height_px=400, fps_overlay=true)
