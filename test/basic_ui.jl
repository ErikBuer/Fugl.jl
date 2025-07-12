using Fugl
using Fugl: Text

function main()
    # Mutable state variable
    showImage = Ref(true)
    slider_value = Ref(0.5f0)

    # External state for the TextBox
    text_state = Ref("Enter text here...")
    is_focused = Ref(false)


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
            IconButton("test/images/logo.png", on_click=() -> (showImage[] = !showImage[])),
            IntrinsicColumn([
                    Container(),
                    Container(HorizontalSlider(slider_value[], 1.0f0, 0.0f0; on_change=(value) -> (slider_value[] = value))),
                    IntrinsicHeight(TextButton("SomeText", on_click=() -> println("Clicked"))),
                    Container(TextBox(text_state[], is_focused[];
                        on_change=(text) -> (text_state[] = text),
                        on_focus_change=(focused) -> (is_focused[] = focused))
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