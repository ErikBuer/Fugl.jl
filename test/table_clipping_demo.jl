using Fugl
using Fugl: Table, TableStyle, TextStyle

function test_table_clipping()

    function MyApp()
        # Create sample data with text of varying lengths
        headers = ["Short", "Medium Length Header", "Very Very Long Header Name"]
        data = [
            ["OK", "This is medium length text", "This is an extremely long piece of text that should definitely be clipped with ellipsis to show truncation"],
            ["Hi", "Moderate text here", "Another very long string of text that exceeds the available space in the cell"],
            ["Yes", "Some text content", "Yet another long text example that demonstrates character-level clipping with dots"]
        ]

        # Create table with no wrapping (clipping mode)
        clipping_style = TableStyle(
            max_wrapped_rows=0,  # No wrapping - clip with ellipsis
            cell_height=30.0f0,
            cell_padding=8.0f0,
            show_grid=true,
            header_background_color=Vec4f(0.8, 0.8, 0.9, 1.0),
            cell_background_color=Vec4f(1.0, 1.0, 1.0, 1.0)
        )

        # Create table with 2-row wrapping and clipping
        wrapping_style = TableStyle(
            max_wrapped_rows=2,  # Allow 2 rows, then clip
            cell_height=50.0f0,  # Taller for wrapped text
            cell_padding=8.0f0,
            show_grid=true,
            header_background_color=Vec4f(0.9, 0.8, 0.8, 1.0),
            cell_background_color=Vec4f(1.0, 1.0, 1.0, 1.0)
        )

        # Create layout with both examples
        IntrinsicColumn([
                IntrinsicHeight(Container(Text("Character-level clipping with ellipsis (max_wrapped_rows=0):"))),
                IntrinsicHeight(Table(headers, data, style=clipping_style)), IntrinsicHeight(Container(Text("Word wrapping with final line clipping (max_wrapped_rows=2):"))),
                IntrinsicHeight(Table(headers, data, style=wrapping_style)),
            ], spacing=20.0f0, padding=20.0f0)
    end

    Fugl.run(MyApp, title="Table Text Clipping Demo", window_width_px=900, window_height_px=600)
end

test_table_clipping()
