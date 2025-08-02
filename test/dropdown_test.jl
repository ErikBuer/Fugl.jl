using Fugl

function test_dropdown()
    # Create dropdown state
    dropdown_state = Ref(DropdownState(
        ["Option 1", "Option 2", "Option 3", "Very Long Option 4", "Option 5"];
        selected_index=1
    ))

    function MyApp()
        IntrinsicColumn([
                IntrinsicHeight(Container(Fugl.Text("Dropdown Demo"))),
                Container(
                    Dropdown(
                        dropdown_state[];
                        on_state_change=(new_state) -> dropdown_state[] = new_state,
                        on_select=(value, index) -> println("Selected: $value (index: $index)")
                    )
                ),
                IntrinsicHeight(Container(Fugl.Text("Selected: $(
                    dropdown_state[].selected_index > 0 ? 
                    dropdown_state[].options[dropdown_state[].selected_index] : 
                    "None"
                )"))),
            ], padding=0.0, spacing=0.0)
    end

    Fugl.run(MyApp, title="Dropdown Test", window_width_px=400, window_height_px=300, debug_overlay=true)
end

test_dropdown()
