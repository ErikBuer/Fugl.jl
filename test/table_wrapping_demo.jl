using Fugl
using Fugl: Text, Table, TableStyle, TextStyle

function test_table_text_wrapping()

    function MyApp()
        # Create sample data with longer text content
        headers = ["Name", "Description", "Status", "Notes"]
        data = [
            ["Alice Johnson", "Senior Software Engineer with expertise in Julia and machine learning", "Active", "Working on core algorithms"],
            ["Bob Smith", "UI/UX Designer specializing in modern web interfaces", "Active", "Currently redesigning the main dashboard"],
            ["Carol Davis", "Project Manager overseeing multiple development teams", "On Leave", "Back next month"],
            ["David Wilson", "Backend Developer focusing on distributed systems and microservices", "Active", "Implementing new API endpoints"],
            ["Eve Brown", "Data Scientist working on predictive analytics and statistical modeling", "Active", "Analyzing customer behavior patterns"]
        ]

        # Create table with text wrapping enabled
        table_style = TableStyle(
            header_background_color=Vec4f(0.7, 0.7, 0.9, 1.0),
            header_text_style=TextStyle(size_px=16, color=Vec4f(0.0, 0.0, 0.0, 1.0)),
            header_height=35.0f0, cell_background_color=Vec4f(0.98, 0.98, 0.98, 1.0),
            cell_text_style=TextStyle(size_px=12, color=Vec4f(0.0, 0.0, 0.0, 1.0)),
            cell_height=60.0f0,  # Taller cells to accommodate wrapped text

            # Text wrapping settings
            max_wrapped_rows=3,  # Allow up to 3 lines of wrapped text (0 = no wrapping)
            show_grid=true,
            grid_color=Vec4f(0.6, 0.6, 0.6, 1.0),
            grid_width=1.0f0, cell_padding=8.0f0, border_color=Vec4f(0.3, 0.3, 0.3, 1.0),
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

    Fugl.run(MyApp, title="Table Text Wrapping Demo", window_width_px=1200, window_height_px=700, fps_overlay=true)
end

test_table_text_wrapping()
