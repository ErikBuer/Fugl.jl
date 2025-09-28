using Fugl

# Create checkbox state
checkbox_state = Ref(false)

function MyApp()
    IntrinsicColumn([
            IntrinsicHeight(Container(Fugl.Text("CheckBox Demo"))),
            Container(
                CheckBox(
                    checkbox_state[];
                    label="Enable feature",
                    on_change=(new_value) -> begin
                        checkbox_state[] = new_value
                        println("Checkbox is now: $(new_value)")
                    end
                )
            ),
            IntrinsicHeight(Container(Fugl.Text("Status: $(
                checkbox_state[] ? "Enabled" : "Disabled"
            )"))),
        ], padding=0.0, spacing=0.0)
end

Fugl.run(MyApp, title="CheckBox Test", window_width_px=400, window_height_px=300, fps_overlay=true)
