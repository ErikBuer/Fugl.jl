using Fugl
using Fugl: Text

function grid_test()
    # Create sample data
    x_data = Float32.(0:0.5:4)
    y_data = Float32.(sin.(x_data))
    line_element = LinePlotElement(y_data, x_data=x_data, color=Vec4{Float32}(0.0, 0.5, 1.0, 1.0))

    # Test with grid enabled but no axis lines
    plot = Plot([line_element], PlotStyle(
        show_grid=true,               # Enable grid
        show_left_axis=false,         # Disable all axis lines
        show_right_axis=false,
        show_top_axis=false,
        show_bottom_axis=false,
        show_x_tick_marks=false,      # Disable tick marks
        show_y_tick_marks=false,
        show_x_tick_labels=false,     # Disable tick labels
        show_y_tick_labels=false
    ))

    ui = IntrinsicColumn([
            IntrinsicHeight(Text("Grid Test: Only Grid Lines (No Axis Lines, No Tick Marks)", style=TextStyle(size_px=16))),
            plot
        ], spacing=10.0, padding=20.0)

    return ui
end

# Run the grid test
Fugl.run(grid_test, title="Grid Test", window_width_px=600, window_height_px=400)
