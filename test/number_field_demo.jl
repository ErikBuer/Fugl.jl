using Fugl
using Fugl: Text

function main()
    # Create different number field states with various types and configurations

    # Float64 field (default)
    float_field_state = Ref(NumberFieldState("123.45"))

    # Integer field
    int_field_state = Ref(NumberFieldState("42";
        options=NumberFieldOptions(Int)))

    # Positive Float32 with max value
    float32_field_state = Ref(NumberFieldState("10.5";
        options=NumberFieldOptions(Float32; allow_negative=false, max_value=100.0f0)))

    # Currency field (Float64 with constraints)
    currency_field_state = Ref(NumberFieldState("19.99";
        options=NumberFieldOptions(Float64; min_value=0.0, max_value=9999.99)))

    # Large integer field
    big_int_field_state = Ref(NumberFieldState("1000";
        options=NumberFieldOptions(Int; min_value=0, max_value=999999)))

    function MyApp()
        IntrinsicColumn([
                # Title
                IntrinsicHeight(Container(Text("Simplified NumberField Demo"))),

                # Float64 field
                IntrinsicHeight(Container(Text("Float64 Field (default):"))),
                Container(
                    NumberField(
                        float_field_state[];
                        on_state_change=(new_state) -> begin
                            float_field_state[] = new_state
                            if is_valid_number(new_state)
                                value = get_numeric_value(new_state)
                                if value !== nothing
                                    println("Float64 value: ", value, " (type: ", typeof(value), ")")
                                end
                            end
                        end,
                        on_change=(new_text) -> println("Float64 text changed to: ", new_text)
                    )
                ),

                # Integer field
                IntrinsicHeight(Container(Text("Integer Field:"))),
                Container(
                    NumberField(
                        int_field_state[];
                        on_state_change=(new_state) -> begin
                            int_field_state[] = new_state
                            if is_valid_number(new_state)
                                value = get_numeric_value(new_state)
                                if value !== nothing
                                    println("Integer value: ", value, " (type: ", typeof(value), ")")
                                end
                            end
                        end,
                        on_change=(new_text) -> println("Integer text changed to: ", new_text)
                    )
                ),

                # Float32 field with constraints
                IntrinsicHeight(Container(Text("Float32 Field (Positive, Max: 100):"))),
                Container(
                    NumberField(
                        float32_field_state[];
                        on_state_change=(new_state) -> begin
                            float32_field_state[] = new_state
                            if is_valid_number(new_state)
                                value = get_numeric_value(new_state)
                                if value !== nothing
                                    println("Float32 value: ", value, " (type: ", typeof(value), ", valid: ", value <= 100.0f0, ")")
                                end
                            end
                        end,
                        on_change=(new_text) -> println("Float32 text changed to: ", new_text)
                    )
                ),

                # Currency field
                IntrinsicHeight(Container(Text("Currency Field (0-9999.99):"))),
                Container(
                    NumberField(
                        currency_field_state[];
                        on_state_change=(new_state) -> begin
                            currency_field_state[] = new_state
                            if is_valid_number(new_state)
                                value = get_numeric_value(new_state)
                                if value !== nothing
                                    println("Currency value: \$", value)
                                end
                            end
                        end,
                        on_change=(new_text) -> println("Currency text changed to: ", new_text)
                    )
                ),

                # Big integer field
                IntrinsicHeight(Container(Text("Big Integer Field (0-999999):"))),
                Container(
                    NumberField(
                        big_int_field_state[];
                        on_state_change=(new_state) -> begin
                            big_int_field_state[] = new_state
                            if is_valid_number(new_state)
                                value = get_numeric_value(new_state)
                                if value !== nothing
                                    println("Big integer value: ", value, " (type: ", typeof(value), ")")
                                end
                            end
                        end,
                        on_change=(new_text) -> println("Big integer text changed to: ", new_text)
                    )
                ),

                # Display current values and validity
                IntrinsicHeight(Container(Text("Current Values:"))),
                IntrinsicHeight(Container(Text("Float64: $(get_text_value(float_field_state[])) (valid: $(is_valid_number(float_field_state[])))"))),
                IntrinsicHeight(Container(Text("Integer: $(get_text_value(int_field_state[])) (valid: $(is_valid_number(int_field_state[])))"))),
                IntrinsicHeight(Container(Text("Float32: $(get_text_value(float32_field_state[])) (valid: $(is_valid_number(float32_field_state[])))"))),
                IntrinsicHeight(Container(Text("Currency: $(get_text_value(currency_field_state[])) (valid: $(is_valid_number(currency_field_state[])))"))),
                IntrinsicHeight(Container(Text("Big Int: $(get_text_value(big_int_field_state[])) (valid: $(is_valid_number(big_int_field_state[])))"))),
            ],
            padding=0, spacing=0
        )
    end

    # Run the GUI
    Fugl.run(MyApp, title="Simplified NumberField Demo", window_width_px=800, window_height_px=800, debug_overlay=true)
end

main()
