using Element
using Element: Text

function main()
    # Mutable state variable
    showImage = Ref(true)
    slider_value = Ref(0.5f0)

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
            Column([
                    Container(),
                    Container(HorizontalSlider(slider_value[], 1.0f0, 0.0f0; on_change=(value) -> (slider_value[] = value))),
                    TextButton("SomeText", on_click=() -> println("Clicked"))],
                padding=0
            )
        ])
    end

    # Run the GUI
    Element.run(MyApp, title="Dynamic UI Example")
    #screenshot(MyApp, "test/test_output/dynamic_ui_example.png", 1920, 1080)
end

main()