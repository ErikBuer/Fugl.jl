using Fugl
using Fugl: Text, Table, TableStyle, TextStyle


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

table = create_simple_large_content()

function MyApp()
    # Wrap in a container for some padding
    Container(
        table,
        style=ContainerStyle(
            background_color=Vec4f(0.95, 0.95, 0.95, 1.0),
            border_width=0.0f0,
            padding=20.0f0
        )
    )
end

Fugl.run(MyApp, title="Table Component Demo", window_width_px=900, window_height_px=600, fps_overlay=true)

