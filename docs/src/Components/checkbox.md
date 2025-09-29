# CheckBox

The `CheckBox` component provides a boolean input control with an optional text label. It supports user-managed state through callbacks and offers comprehensive styling options.

## Basic Usage

The CheckBox requires user-managed state using a `Ref{Bool}` and provides callbacks for state changes.

```@example CheckBoxBasic
using Fugl

# Create checkbox state  
checkbox_state = Ref(false)
checkbox_state2 = Ref(true)

function MyApp()
    Card(
        "CheckBox Demo",
        Column(
            CheckBox(
                checkbox_state[];
                label="Enable feature",
                on_change=(new_value) -> begin
                    checkbox_state[] = new_value
                    println("Checkbox is now: $(new_value)")
                end
            ),
            CheckBox(
                checkbox_state2[];
                label="Enable feature 2",
                on_change=(new_value) -> begin
                    checkbox_state2[] = new_value
                    println("Checkbox 2 is now: $(new_value)")
                end
            )
        )
    )
end

screenshot(MyApp, "checkbox_basic.png", 400, 120);
nothing #hide
```

![Basic CheckBox](checkbox_basic.png)
