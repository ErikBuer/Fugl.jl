using Fugl
using Fugl: Table, TableStyle, TextStyle

function test_wrapping_modes()

    function MyApp()
        # Sample data with long text
        headers = ["Mode", "Text Content"]
        data = [
            ["No Wrapping", "This is a very long text that should be clipped and not wrapped at all in the cell"],
            ["2 Row Wrap", "This text will wrap to a maximum of two rows and then clip any additional content"],
            ["3 Row Wrap", "This longer text content will be allowed to wrap up to three rows before clipping occurs"]
        ]

        # Create table styles for different wrapping modes
        no_wrap_style = TableStyle(
            max_wrapped_rows=0,  # No wrapping
            wrap_text=false,
            cell_height=30.0f0,
            cell_padding=8.0f0,
            show_grid=true,
            header_background_color=Vec4f(0.7, 0.7, 0.9, 1.0),
            header_text_style=TextStyle(size_px=16, color=Vec4f(0.0, 0.0, 0.0, 1.0)),
            cell_background_color=Vec4f(1.0, 1.0, 1.0, 1.0)
        )

        two_row_style = TableStyle(
            max_wrapped_rows=2,  # Max 2 rows
            wrap_text=true,
            cell_height=50.0f0,  # Taller for 2 rows
            cell_padding=8.0f0,
            show_grid=true,
            header_background_color=Vec4f(0.7, 0.7, 0.9, 1.0),
            header_text_style=TextStyle(size_px=16, color=Vec4f(0.0, 0.0, 0.0, 1.0)),
            cell_background_color=Vec4f(1.0, 1.0, 1.0, 1.0)
        )

        three_row_style = TableStyle(
            max_wrapped_rows=3,  # Max 3 rows
            wrap_text=true,
            cell_height=70.0f0,  # Taller for 3 rows
            cell_padding=8.0f0,
            show_grid=true,
            header_background_color=Vec4f(0.7, 0.7, 0.9, 1.0),
            header_text_style=TextStyle(size_px=16, color=Vec4f(0.0, 0.0, 0.0, 1.0)),
            cell_background_color=Vec4f(1.0, 1.0, 1.0, 1.0)
        )        # Create three tables to show different modes
        IntrinsicColumn([
                IntrinsicHeight(Container(Text("No Wrapping (max_wrapped_rows=0):"))),
                IntrinsicHeight(Table(headers, [data[1]], style=no_wrap_style)), IntrinsicHeight(Container(Text("2 Row Wrapping (max_wrapped_rows=2):"))),
                IntrinsicHeight(Table(headers, [data[2]], style=two_row_style)), IntrinsicHeight(Container(Text("3 Row Wrapping (max_wrapped_rows=3):"))),
                IntrinsicHeight(Table(headers, [data[3]], style=three_row_style)),
            ], spacing=20.0f0, padding=20.0f0)
    end

    Fugl.run(MyApp, title="Table Wrapping Modes Demo", window_width_px=800, window_height_px=600, fps_overlay=true)
end

test_wrapping_modes()
