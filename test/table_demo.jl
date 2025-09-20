using Fugl
using Fugl: Text, Table, TableStyle, TextStyle

function test_table()

    function MyApp()
        # Create sample data
        headers = ["Name", "Age", "City", "Occupation"]
        data = [
            ["Alice Johnson", "28", "New York", "Engineer"],
            ["Bob Smith", "35", "London", "Designer"],
            ["Carol Davis", "31", "Tokyo", "Manager"],
            ["David Wilson", "26", "Paris", "Developer"],
            ["Eve Brown", "33", "Berlin", "Analyst"]
        ]

        # Create table with custom styling
        table_style = TableStyle(
            header_background_color=Vec4f(0.7, 0.7, 0.9, 1.0),
            header_text_style=TextStyle(size_px=16, color=Vec4f(0.0, 0.0, 0.0, 1.0)),
            header_height=35.0f0, cell_background_color=Vec4f(0.98, 0.98, 0.98, 1.0),
            cell_text_style=TextStyle(size_px=14, color=Vec4f(0.0, 0.0, 0.0, 1.0)),
            cell_height=30.0f0, show_grid=true,
            grid_color=Vec4f(0.6, 0.6, 0.6, 1.0),
            grid_width=1.0f0, cell_padding=10.0f0, border_color=Vec4f(0.3, 0.3, 0.3, 1.0),
            border_width=2.0f0
        )

        # Create the table with click handling
        table = Table(
            headers,
            data,
            style=table_style,
            on_cell_click=(row, col) -> begin
                println("Clicked cell at row $row, column $col")
                if row <= length(data) && col <= length(headers)
                    println("Content: $(data[row][col])")
                    println("Column: $(headers[col])")
                end
            end
        )

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
end

test_table()
