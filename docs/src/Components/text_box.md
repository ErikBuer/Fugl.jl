# TextBox

``` @example TextBoxExample
using Fugl
using Fugl: Text

text_box_state = Ref(EditorState("Enter your text here..."))

function MyApp()
    IntrinsicColumn([
        IntrinsicHeight(Container(Text("Text Editor Generalization Demo"))),

        # Text Box Section
        IntrinsicHeight(Container(Text("Plain Text Box:"))),
        Container(
            TextBox(
                text_box_state[];
                on_state_change=(new_state) -> text_box_state[] = new_state,
                on_change=(new_text) -> println("Optional hook. Text is now: ", new_text[1:min(20, length(new_text))], "...")
            )
        ),
    ], padding=0.0, spacing=0.0)
end

screenshot(MyApp, "textBox.png", 840, 400);
nothing #hide
```

![Text Box](textBox.png)
