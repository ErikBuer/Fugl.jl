#!/usr/bin/env julia

using Fugl

function test_axis_labels()
    # Create plot style with both x and y labels
    plot_style = PlotStyle(
        x_label="X Axis Label",
        y_label="Y Axis Label",
        show_x_label=true,
        show_y_label=true
    )

    # Create some test data
    y_data = [1.0, 4.0, 2.0, 5.0, 3.0, 2.5, 4.5, 1.5]

    # Create a plot element
    line_element = LinePlotElement(y_data, x_data=collect(1.0:length(y_data)))

    # Create the plot
    plot_view = Plot([line_element], plot_style)

    # Create a simple UI that just shows the plot
    ui() = Container(
        FixedSize(plot_view, 800, 600),
        style=ContainerStyle(background_color=Vec4{Float32}(0.1f0, 0.1f0, 0.1f0, 1.0f0))
    )

    # Run the UI
    Fugl.run(ui, title="Axis Labels Test", window_width_px=1000, window_height_px=700)
end

test_axis_labels()
