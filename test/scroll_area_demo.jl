using Fugl

function create_simple_large_content()
    # Create a simple table as content to scroll
    headers = ["ID", "Name", "Value"]
    data = Vector{Vector{String}}()

    for i in 1:50  # Back to 50 rows to test scrolling
        push!(data, [
            string(i),
            "Item $i",
            "Value $(i * 10)"
        ])
    end

    # Create table style
    style = TableStyle(
        header_background_color=Vec4f(0.3, 0.5, 0.9, 1.0),
        header_text_style=TextStyle(size_px=14, color=Vec4f(1.0, 1.0, 1.0, 1.0)),
        header_height=30.0f0,
        cell_background_color=Vec4f(1.0, 1.0, 1.0, 1.0),
        cell_alternate_background_color=Vec4f(0.95, 0.95, 0.95, 1.0),
        cell_text_style=TextStyle(size_px=12, color=Vec4f(0.0, 0.0, 0.0, 1.0)),
        cell_height=25.0f0,
        show_grid=true,
        grid_color=Vec4f(0.8, 0.8, 0.8, 1.0),
        grid_width=1.0f0,
        cell_padding=6.0f0
    )

    # Create table without scroll state (let ScrollArea handle it)
    table = Table(
        headers,
        data,
        style=style,
        on_cell_click=(row, col) -> begin
            if row <= length(data) && col <= length(headers)
                println("Clicked row $row ($(headers[col])): $(data[row][col])")
            end
        end
    )

    return table
end

mutable struct ScrollDemo
    table_height::Float32  # Cache calculated table height
end


# Create large content
content = create_simple_large_content()

# Calculate expected table height: header + (num_rows * cell_height)
expected_table_height = 30.0f0 + (50 * 25.0f0)  # header_height + (rows * cell_height)

app_state = ScrollDemo(expected_table_height)

scroll_state = Ref(ScrollAreaState())

# Create scroll area style
scroll_style = ScrollAreaStyle(
    scrollbar_width=4.0f0,  # Make it tiny as visual aid only
    scrollbar_color=Vec4f(0.6, 0.6, 0.6, 0.8),  # Slightly transparent
    scrollbar_background_color=Vec4f(0.95, 0.95, 0.95, 0.3),  # Very transparent background
    scrollbar_hover_color=Vec4f(0.6, 0.6, 0.6, 0.8),  # Same as normal color since not interactive
    corner_color=Vec4f(0.95, 0.95, 0.95, 0.3)  # Transparent corner
)


function test_scroll_area()
    Card(
        "ScrollArea Demo - Use mouse wheel to scroll",
        ScrollArea(
            content,
            scroll_state=scroll_state[],
            style=scroll_style,
            enable_horizontal=false,  # Start with vertical only
            enable_vertical=true,
            show_scrollbars=true,
            on_scroll_change=(new_state) -> scroll_state[] = new_state,
            on_click=(x, y) -> println("Clicked in scroll area at: ($x, $y)")
        )
    )

end

# Run the scroll area demo
Fugl.run(test_scroll_area,
    title="ScrollArea Demo - Use mouse wheel to scroll",
    window_width_px=700,
    window_height_px=500,
    fps_overlay=true
)
