using Fugl
using Fugl: Text, LinePlotElement, ScatterPlotElement, StemPlotElement, SOLID, DASH, DOT, CIRCLE, TRIANGLE, RECTANGLE

# Modal state for legend position (nothing = centered)
legend_modal_state = Ref(ModalState(
    offset_x=50.0f0,
    offset_y=50.0f0
))

# Plot state for zoom/pan interaction
plot_state = Ref(PlotState())

# Dark mode styles
modal_style = ModalStyle(
    background_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.0f0)
)

legend_card_style = ContainerStyle(
    background_color=Vec4f(0.18, 0.18, 0.22, 0.95),
    border_color=Vec4f(0.3, 0.3, 0.35, 1.0),
    border_width=2.0f0,
    padding=12.0f0,
    corner_radius=8.0f0
)

plot_card_style = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

title_text_style = TextStyle(size_px=18, color=Vec4f(0.9, 0.9, 0.95, 1.0))
legend_text_style = TextStyle(size_px=12, color=Vec4f(0.9, 0.9, 0.95, 1.0))

function MyApp()
    # Generate sample data
    x_data = collect(0.0:0.1:10.0)
    y1_data = sin.(x_data)
    y2_data = cos.(x_data)
    y3_data = sin.(x_data .* 2) .* 0.5

    # Create plot elements with labels
    elements = [
        LinePlotElement(y1_data; x_data=x_data,
            color=Vec4{Float32}(0.4, 0.6, 0.9, 1.0),
            width=3.0f0,
            line_style=SOLID,
            label="Sine Wave"
        ),
        LinePlotElement(y2_data; x_data=x_data,
            color=Vec4{Float32}(0.9, 0.4, 0.4, 1.0),
            width=2.5f0,
            line_style=DASH,
            label="Cosine Wave"
        ),
        ScatterPlotElement(y3_data; x_data=x_data,
            fill_color=Vec4{Float32}(0.4, 0.9, 0.4, 1.0),
            border_color=Vec4{Float32}(0.2, 0.7, 0.2, 1.0),
            marker_size=6.0f0,
            border_width=1.5f0,
            marker_type=CIRCLE,
            label="Double Frequency"
        )
    ]

    # Wrap plot in modal with legend
    Modal(
        # Background: The plot
        Card(
            "Plot with Draggable Legend",
            Plot(
                elements,
                PlotStyle(
                    background_color=Vec4{Float32}(0.08, 0.10, 0.14, 1.0),
                    grid_color=Vec4{Float32}(0.25, 0.25, 0.30, 1.0),
                    axis_color=Vec4{Float32}(0.9, 0.9, 0.95, 1.0),
                    show_grid=true,
                    padding=54.0f0,
                    x_label="Time (s)",
                    y_label="Amplitude",
                    show_x_label=true,
                    show_y_label=true,
                ),
                plot_state[],
                (new_state) -> plot_state[] = new_state
            ),
            style=plot_card_style,
            title_style=title_text_style
        ),
        # Modal child: The legend
        Container(
            Legend(elements, text_style=legend_text_style, spacing=8.0f0, item_height=24.0f0),
            style=legend_card_style
        ),
        child_width=200.0f0,
        child_height=120.0f0,
        state=legend_modal_state[],
        style=modal_style,
        on_state_change=(new_state) -> legend_modal_state[] = new_state,
        capture_clicks_outside=false
    )
end

Fugl.run(MyApp, title="Plot Legend Demo", window_width_px=1000, window_height_px=700, fps_overlay=true)
