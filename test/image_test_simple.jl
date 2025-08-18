using Fugl
using Fugl: Text

function simple_image_test()
    # Create a simple test pattern - half red, half blue
    size_x, size_y = 20, 20
    data = Matrix{Float32}(undef, size_y, size_x)

    for j in 1:size_y
        for i in 1:size_x
            if i <= size_x ÷ 2
                data[j, i] = 0.0f0  # Will be dark blue in viridis
            else
                data[j, i] = 1.0f0  # Will be bright yellow in viridis
            end
        end
    end

    # Create plot element
    elements = AbstractPlotElement[
        ImagePlotElement(
        data;
        x_range=(0.0, 10.0),
        y_range=(0.0, 10.0),
        colormap=:viridis,
        label="Test Pattern"
    )
    ]

    function MyApp()
        IntrinsicColumn([
                IntrinsicHeight(Container(Text("Simple Image Test - Should show dark blue (left) and yellow (right)"))),
                Container(
                    Plot(
                        elements,
                        PlotStyle(
                            show_grid=true,
                            show_axes=true,
                            show_legend=true,
                            padding_px=50.0f0
                        )
                    )
                ),
            ], padding=0.0, spacing=0.0)
    end

    Fugl.run(MyApp, title="Simple Image Test", window_width_px=800, window_height_px=600, fps_overlay=true)
end

simple_image_test()
