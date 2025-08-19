using Fugl

function simple_colorbar_test()
    # Just test a vertical colorbar by itself
    colorbar = VerticalColorbar(:viridis, (0.0f0, 1.0f0))

    plot = Plot([colorbar], PlotStyle(
        show_grid=false,
        show_left_axis=true,
        show_right_axis=false,
        show_top_axis=false,
        show_bottom_axis=true,
        show_x_tick_marks=false,
        show_y_tick_marks=true,
        show_x_tick_labels=false,
        show_y_tick_labels=true
    ))

    ui = FixedSize(plot, 200.0f0, 400.0f0)
    return ui
end

# Run the simple test
println("Starting simple colorbar test...")
Fugl.run(simple_colorbar_test, title="Simple Colorbar Test", window_width_px=300, window_height_px=500)
