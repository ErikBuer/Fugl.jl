using Fugl
using Fugl: Text, LinePlotElement, ScatterPlotElement, StemPlotElement

function main()
    # User manages all state - no internal mutation
    time_data = Ref(collect(0.0:0.1:10.0))
    sin_data = Ref(sin.(time_data[]))
    cos_data = Ref(cos.(time_data[]))

    # Additional data for different plot types
    element_count = Ref(20)  # Reduced for better stem/scatter visibility
    weights = Ref(ones(element_count[]))
    random_data = Ref(rand(element_count[]) .* 2 .- 1)  # Random data between -1 and 1
    discrete_x = Ref(collect(1:element_count[]))

    frame_count = Ref(0)

    function MyApp()
        frame_count[] += 1

        new_time = time_data[][end] + 0.1

        # User manages data - append and limit size themselves
        push!(time_data[], new_time)
        push!(sin_data[], sin(new_time))
        push!(cos_data[], cos(new_time))

        # Update random data for scatter plot
        random_data[] = rand(element_count[]) .* 2 .- 1

        # User controls window size (keep last 200 points)
        max_points = 200
        if length(time_data[]) > max_points
            time_data[] = time_data[][(end-max_points+1):end]
            sin_data[] = sin_data[][(end-max_points+1):end]
            cos_data[] = cos_data[][(end-max_points+1):end]
        end

        # Create mixed plot with different element types
        mixed_elements = [
            LinePlotElement(
                sin_data[];
                x_data=time_data[],
                color=Vec4{Float32}(1.0, 0.2, 0.2, 1.0),
                width=3.0f0,
                label="sin(x) - Line"
            ),
            LinePlotElement(
                cos_data[];
                x_data=time_data[],
                color=Vec4{Float32}(0.2, 0.2, 1.0, 1.0),
                width=2.0f0,
                label="cos(x) - Line"
            )
        ]

        # Create scatter plot elements
        scatter_elements = [
            ScatterPlotElement(
                random_data[];
                x_data=discrete_x[],
                color=Vec4{Float32}(0.8, 0.6, 0.2, 1.0),
                marker_size=8.0f0,
                label="Random Scatter"
            )
        ]

        # Create stem plot elements
        stem_elements = [
            StemPlotElement(
                weights[];
                x_data=discrete_x[],
                color=Vec4{Float32}(0.2, 0.8, 0.2, 1.0),
                width=3.0f0,
                baseline=0.0f0,
                label="Ones - Stem"
            )
        ]

        # Single line plot for comparison
        simple_line = [
            LinePlotElement(
                [1, 2, 3, 2, 1];
                color=Vec4{Float32}(0.6, 0.2, 0.8, 1.0),
                width=4.0f0,
                label="Simple Line"
            )
        ]

        IntrinsicColumn([
                IntrinsicHeight(Container(Text("Multi-Type Plot Demo - User-Managed State"))),

                # Mixed plot with line elements
                IntrinsicHeight(Container(Text("Mixed Line Plot (sin + cos)"))),
                Container(
                    Plot(
                        mixed_elements,
                        PlotStyle(
                            background_color=Vec4{Float32}(0.95, 0.95, 0.95, 1.0),
                            show_grid=true,
                            show_axes=true
                        )
                    )
                ),

                # Scatter plot
                IntrinsicHeight(Container(Text("Scatter Plot (Random Data)"))),
                Container(
                    Plot(
                        scatter_elements,
                        PlotStyle(
                            background_color=Vec4{Float32}(0.9, 0.9, 1.0, 1.0),
                            show_grid=true,
                            show_axes=true
                        )
                    )
                ),

                # Stem plot
                IntrinsicHeight(Container(Text("Stem Plot (Ones)"))),
                Container(
                    Plot(
                        stem_elements,
                        PlotStyle(
                            background_color=Vec4{Float32}(0.9, 1.0, 0.9, 1.0),
                            show_grid=true,
                            show_axes=true
                        )
                    )
                ),

                # Simple line plot using Plot constructor
                IntrinsicHeight(Container(Text("Simple Line Plot (Plot Constructor)"))),
                Container(
                    Plot(
                        [LinePlotElement([1, 2, 3, 2, 1]; color=Vec4{Float32}(0.6, 0.2, 0.8, 1.0), width=4.0f0, label="Simple Line")],
                        PlotStyle(
                            background_color=Vec4{Float32}(1.0, 0.9, 0.9, 1.0),
                            show_grid=true,
                            show_axes=true
                        )
                    )
                ),
            ], padding=0.0, spacing=0.0)
    end

    Fugl.run(MyApp, title="Multi-Type Plot Demo - Line, Scatter, Stem", window_width_px=1200, window_height_px=1000, fps_overlay=true)
end

main()
