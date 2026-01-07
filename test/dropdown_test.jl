using Fugl

function test_dropdown()
    # Create dropdown state with many options to test scrolling
    many_options = ["Option $i" for i in 1:20]  # 20 options to test scrolling
    dropdown_state = Ref(DropdownState(
        many_options;
        selected_index=1,
        scroll_offset=0
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

    Fugl.run(MyApp, title="Dropdown Test", window_width_px=400, window_height_px=300, fps_overlay=true)
end

test_dropdown()