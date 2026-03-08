using Fugl

function main()
    selected_tab = Ref(1)

    function MyApp()
        Tabs(
            [
                ("First", Fugl.Text("Content of first tab")),
                ("Second", Fugl.Text("Content of second tab")),
                ("Third", Fugl.Text("Content of third tab"))
            ];
            selected_index=selected_tab[],
            on_tab_change=(index) -> selected_tab[] = index
        )
    end

    Fugl.run(MyApp; title="Simple Tabs", window_width_px=600, window_height_px=400)
end

main()
