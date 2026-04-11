using Fugl
using Fugl: Text

function main()
    # Create a long list to test scrolling
    options = ["Option $i" for i in 1:20]

    # State for the multi-select list
    list_state = Ref(MultiSelectState(length(options)))

    # Style with limited visible items
    list_style = MultiSelectListStyle(
        max_visible_items=8,
        item_height=30.0f0,
        padding=10.0f0,
        corner_radius=5.0f0,
        border_width=1.0f0,
        border_color=Vec4{Float32}(0.3f0, 0.3f0, 0.3f0, 1.0f0),
        item_background=Vec4{Float32}(0.2f0, 0.2f0, 0.2f0, 1.0f0),
        item_hover_color=Vec4{Float32}(0.3f0, 0.3f0, 0.3f0, 1.0f0),
        item_selected_color=Vec4{Float32}(0.1f0, 0.4f0, 0.8f0, 1.0f0),
        item_selected_hover_color=Vec4{Float32}(0.2f0, 0.5f0, 0.9f0, 1.0f0),
    )

    function MyApp()
        Column([
                Text("Scrollable MultiSelect Demo"),
                Text("Use scroll wheel to navigate. Only 8 items visible at once."),
                FixedSize(
                    MultiSelectList(
                        options,
                        list_state[];
                        style=list_style,
                        on_state_change=(new_state) -> list_state[] = new_state,
                        on_change=(selected) -> println("Selected: ", [options[i] for i in selected]),
                    ),
                    400.0f0, 300.0f0
                )
            ]; spacing=20.0f0)
    end

    MyApp()
end

main()