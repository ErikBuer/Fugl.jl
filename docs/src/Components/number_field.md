# Number Field

The NumberField component provides type-safe numeric input with automatic parsing and validation. It extends the TextBox functionality to handle numeric types like `Int`, `Float32`, `Float64`, etc.

``` @example NumberFieldExample
using Fugl

function MyApp()
    # Store EditorState instead of values
    int_state = Ref(EditorState("42"))
    float_state = Ref(EditorState("123.45"))

    IntrinsicColumn([
        IntrinsicHeight(Container(Fugl.Text("Number Field Demo - Type Casting"))),

        # Integer field
        IntrinsicHeight(Container(Fugl.Text("Integer Field:"))),
        Container(
            NumberField(
                int_state[];
                type=Int,
                on_state_change=(new_state) -> int_state[] = new_state,
                on_change=(new_value) -> println("Integer changed to: ", new_value, " (type: ", typeof(new_value), ")")
            )
        ),

        # Float32 field
        IntrinsicHeight(Container(Fugl.Text("Float32 Field:"))),
        Container(
            NumberField(
                float_state[];
                type=Float32,
                on_state_change=(new_state) -> float_state[] = new_state,
                on_change=(new_value) -> println("Float32 changed to: ", new_value, " (type: ", typeof(new_value), ")")
            )
        ),

        # Display current values - display the state text and parsed values
        IntrinsicHeight(Container(Fugl.Text("Current Values:"))),
        IntrinsicHeight(Container(Fugl.Text("Integer: $(int_state[].text)"))),
        IntrinsicHeight(Container(Fugl.Text("Float32: $(float_state[].text)"))),
    ], padding=0.0, spacing=0.0)
end

screenshot(MyApp, "numberField.png", 600, 400);
nothing #hide
```

![Number Field](numberField.png)
