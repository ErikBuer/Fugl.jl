using Fugl
using Fugl: Text

function main()
    # Mutable state variable
    showImage = Ref(true)
    slider_value = Ref(0.5f0)

    # External state for the TextBox
    text_box_state = Ref(EditorState("Enter text here..."))

    function MyApp()
        Row([
            Container(Text("Hello World")),
            Container(
                if showImage[]
                    Image("test/images/logo.png")
                else
                    Text("Click to show image")
                end,
                on_click=() -> (showImage[] = !showImage[])
            ),
            AlignHorizontal(FixedSize(IconButton("test/images/logo.png"; on_click=() -> (showImage[] = !showImage[])), 100f0, 100f0), :center),
            IntrinsicColumn([
                    Container(),
                    Container(HorizontalSlider(slider_value[], 1.0f0, 0.0f0; on_change=(value) -> (slider_value[] = value))),
                    IntrinsicHeight(TextButton("SomeText", on_click=() -> println("Clicked"))),
                    Container(
                        TextBox(
                            text_box_state[];
                            on_change=(new_state) -> text_box_state[] = new_state,
                            on_focus_change=(focused) -> text_box_state[] = EditorState(text_box_state[]; is_focused=focused)
                        )
                    )
                ],
                padding=0
            )
        ])
    end

    # Run the GUI
    Fugl.run(MyApp, title="Dynamic UI Example")
    #screenshot(MyApp, "test/test_output/dynamic_ui_example.png", 1920, 1080)
end

main()