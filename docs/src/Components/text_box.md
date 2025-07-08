# TextBox

``` @example TextBoxExample
using Fugl

text_state = Ref("Enter text here...")
is_focused = Ref(false)

function MyApp()
    Container(
        TextBox(text_state[], is_focused[];
            on_change=(text) -> (text_state[] = text),
            on_focus_change=(focused) -> (is_focused[] = focused)
        )
    )
end

screenshot(MyApp, "textBox.png", 400, 150);
nothing #hide
```

![Text Box](textBox.png)
