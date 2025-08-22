using Fugl
using Fugl: Text

function main()
    # Store EditorState instead of values
    int_state = Ref(EditorState("42"))
    float_state = Ref(EditorState("123.45"))

    function MyApp()
        IntrinsicColumn([
                IntrinsicHeight(Container(Text("NumberField Demo - Type Casting"))),

                # Integer field
                IntrinsicHeight(Container(Text("Integer Field:"))),
                Container(
                    NumberField(
                        int_state[];
                        type=Int,
                        on_state_change=(new_state) -> int_state[] = new_state,
                        on_change=(new_value) -> println("Integer changed to: ", new_value, " (type: ", typeof(new_value), ")")
                    )
                ),

                # Float32 field
                IntrinsicHeight(Container(Text("Float32 Field:"))),
                Container(
                    NumberField(
                        float_state[];
                        type=Float32,
                        on_state_change=(new_state) -> float_state[] = new_state,
                        on_change=(new_value) -> println("Float32 changed to: ", new_value, " (type: ", typeof(new_value), ")")
                    )
                ),

                # Display current values - display the state text and parsed values
                IntrinsicHeight(Container(Text("Current Values:"))),
                IntrinsicHeight(Container(Text("Integer: $(int_state[].text)"))),
                IntrinsicHeight(Container(Text("Float32: $(float_state[].text)"))),
            ], padding=0.0, spacing=0.0)
    end

    Fugl.run(MyApp, title="Number Field Demo", window_width_px=600, window_height_px=400, fps_overlay=true)
end

main()