using Fugl
using Fugl: Text

function main()
    # Create different number field states with type safety
    int_state = Ref(NumberFieldState(42; options=NumberFieldOptions(Int)))
    float_state = Ref(NumberFieldState(123.45; options=NumberFieldOptions(Float64; min_value=0.0, max_value=1000.0)))

    function MyApp()
        IntrinsicColumn([
            IntrinsicHeight(Container(Text("Number Field Demo - Always Valid Values"))),

            # Integer field
            IntrinsicHeight(Container(Text("Integer Field:"))),
            Container(
                NumberField(
                    int_state[];
                    on_state_change=(new_state) -> begin
                        int_state[] = new_state
                        println("Integer value: ", new_state.current_value, " (type: ", typeof(new_state.current_value), ")")
                    end,
                    on_change=(new_text) -> println("Integer text changed: ", new_text)
                )
            ),

            # Float field with constraints
            IntrinsicHeight(Container(Text("Float64 Field (0-1000):"))),
            Container(
                NumberField(
                    float_state[];
                    on_state_change=(new_state) -> begin
                        float_state[] = new_state
                        println("Float64 value: ", new_state.current_value, " (type: ", typeof(new_state.current_value), ")")
                    end,
                    on_change=(new_text) -> println("Float64 text changed: ", new_text)
                )
            ),

            # Display current values - direct access, no getters!
            IntrinsicHeight(Container(Text("Current Values:"))),
            IntrinsicHeight(Container(Text("Integer: $(int_state[].current_value)"))),
            IntrinsicHeight(Container(Text("Float64: $(float_state[].current_value)"))),
        ])
    end

    Fugl.run(MyApp, title="Number Field Demo", window_width_px=600, window_height_px=400, debug_overlay=true)
end

main()