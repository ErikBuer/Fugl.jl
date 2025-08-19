using Fugl

function minimal_colorbar_test()
    # Create a simple vertical colorbar
    colorbar = VerticalColorbar(:viridis, (0.0f0, 1.0f0))

    # Create a simple plot with just the colorbar
    ui = Plot([colorbar], PlotStyle(
        show_left_axis=true,
        show_right_axis=true,
        show_top_axis=true,
        show_bottom_axis=true,
        show_x_ticks=false,
        show_y_ticks=true
    ))

    return ui
end

# Run the minimal test
Fugl.run(minimal_colorbar_test, title="Minimal Colorbar Test", window_width_px=400, window_height_px=600, fps_overlay=true)
