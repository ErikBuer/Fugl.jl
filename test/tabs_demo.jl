using Fugl

function main()
    # State to track which tab is selected
    selected_tab = Ref(1)

    # State for checkboxes
    option1 = Ref(false)
    option2 = Ref(true)
    option3 = Ref(false)

    # State for code editor
    editor_state = Ref(EditorState("# Code Editor\n\nfunction hello()\n    println(\"Hello from Tab 3!\")\nend\n\nhello()"))

    # Create the main app function
    function MyApp()
        # Tab background color matching the tabs
        tab_bg = Vec4(0.18f0, 0.18f0, 0.18f0, 1.0f0)

        # Create tab content with current state values
        tab1_content = Container(
            Column([
                Fugl.Text("Welcome to Tab 1!"; style=TextStyle(size_px=20, color=Vec4(1.0f0, 1.0f0, 1.0f0, 1.0f0))),
                Padding(
                    Fugl.Text("This is the first tab with some text content."; style=TextStyle(size_px=14)),
                    10.0f0
                ),
                TextButton(
                    "Click me!";
                    on_click=() -> println("Button in Tab 1 clicked!")
                )
            ]);
            style=ContainerStyle(background_color=tab_bg, padding=10.0f0)
        )

        tab2_content = Container(
            Column([
                Fugl.Text("Tab 2: Interactive Elements"; style=TextStyle(size_px=20, color=Vec4(1.0f0, 1.0f0, 0.0f0, 1.0f0))),
                Container(
                    Column([
                        CheckBox(
                            option1[];
                            label="Option 1",
                            on_change=(checked) -> begin
                                option1[] = checked
                                println("Option 1: $checked")
                            end
                        ),
                        CheckBox(
                            option2[];
                            label="Option 2",
                            on_change=(checked) -> begin
                                option2[] = checked
                                println("Option 2: $checked")
                            end
                        ),
                        CheckBox(
                            option3[];
                            label="Option 3",
                            on_change=(checked) -> begin
                                option3[] = checked
                                println("Option 3: $checked")
                            end
                        )
                    ]);
                    style=ContainerStyle(
                        background_color=Vec4(0.2f0, 0.2f0, 0.3f0, 1.0f0),
                        border_color=Vec4(0.4f0, 0.4f0, 0.5f0, 1.0f0),
                        corner_radius=5.0f0
                    )
                )
            ]);
            style=ContainerStyle(background_color=tab_bg, padding=10.0f0)
        )

        tab3_content = Container(
            Column([
                Fugl.Text("Tab 3: Code Editor"; style=TextStyle(size_px=20, color=Vec4(0.0f0, 1.0f0, 1.0f0, 1.0f0))),
                FixedHeight(
                    CodeEditor(
                        editor_state[];
                        on_state_change=(new_state) -> editor_state[] = new_state
                    ),
                    400.0f0
                )
            ]);
            style=ContainerStyle(background_color=tab_bg, padding=10.0f0)
        )

        # A simple table for tab 4
        tab4_content = Container(
            Column([
                Fugl.Text("Tab 4: Data View"; style=TextStyle(size_px=20, color=Vec4(1.0f0, 0.5f0, 0.0f0, 1.0f0))),
                Padding(
                    Container(
                        Column([
                            Row([Fugl.Text("Name:"; style=TextStyle(size_px=14)), Fugl.Text("John Doe"; style=TextStyle(size_px=14, color=Vec4(0.7f0, 0.7f0, 0.7f0, 1.0f0)))]),
                            Row([Fugl.Text("Age:"; style=TextStyle(size_px=14)), Fugl.Text("30"; style=TextStyle(size_px=14, color=Vec4(0.7f0, 0.7f0, 0.7f0, 1.0f0)))]),
                            Row([Fugl.Text("Location:"; style=TextStyle(size_px=14)), Fugl.Text("San Francisco"; style=TextStyle(size_px=14, color=Vec4(0.7f0, 0.7f0, 0.7f0, 1.0f0)))]),
                            Row([Fugl.Text("Profession:"; style=TextStyle(size_px=14)), Fugl.Text("Developer"; style=TextStyle(size_px=14, color=Vec4(0.7f0, 0.7f0, 0.7f0, 1.0f0)))])
                        ]);
                        style=ContainerStyle(
                            background_color=Vec4(0.1f0, 0.1f0, 0.1f0, 1.0f0),
                            border_color=Vec4(0.3f0, 0.3f0, 0.3f0, 1.0f0),
                            corner_radius=5.0f0
                        )
                    ),
                    10.0f0
                )
            ]);
            style=ContainerStyle(background_color=tab_bg, padding=10.0f0)
        )

        Container(
            Column([
                Fugl.Text("Tabs Component Demo"; style=TextStyle(size_px=24, color=Vec4(1.0f0, 1.0f0, 1.0f0, 1.0f0))), Tabs(
                    [
                        ("Home", tab1_content),
                        ("Options", tab2_content),
                        ("Code", tab3_content),
                        ("Data", tab4_content)
                    ];
                    selected_index=selected_tab[],
                    on_tab_change=(index) -> begin
                        selected_tab[] = index
                        println("Switched to tab $index")
                    end,
                    style=TabsStyle(
                        tab_height=40.0f0,
                        selected_color=Vec4(0.18f0, 0.18f0, 0.18f0, 1.0f0),
                        unselected_color=Vec4(0.18f0, 0.18f0, 0.18f0, 1.0f0),
                        tab_corner_radius=8.0f0,
                        tab_border_width=2.5f0,
                        selected_border_color=Vec4(0.3f0, 0.6f0, 0.95f0, 1.0f0),
                        unselected_border_color=Vec4(0.25f0, 0.25f0, 0.25f0, 1.0f0)
                    )
                ),
            ]);
            style=ContainerStyle(
                background_color=Vec4(0.15f0, 0.15f0, 0.15f0, 1.0f0)
            )
        )
    end

    # Run the app
    Fugl.run(MyApp; title="Tabs Demo", window_width_px=800, window_height_px=600)
end

main()
