# MultiSelectList

The `MultiSelectList` component displays a list of labeled rows where the user can select one or more items by clicking. Selected rows highlight and can be deselected by clicking again.

State is managed externally via `MultiSelectState`, following the same pattern as other form components.

## Basic Usage

```@example MultiSelectList
using Fugl

options = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
list_state = Ref(MultiSelectState(length(options)))

function MyApp()
    Card(
        "Pick your fruits:",
        MultiSelectList(
            options,
            list_state[];
            on_state_change=(new_state) -> list_state[] = new_state,
            on_change=(selected) -> println("Selected indices: ", sort(collect(selected))),
        )
    )
end

screenshot(MyApp, "multi_select_basic.png", 400, 250);
nothing #hide
```

![Basic MultiSelectList](multi_select_basic.png)

## Pre-selected Items

Pass a `Set{Int}` of 1-based indices to `MultiSelectState` to start with items already selected.

```@example MultiSelectList
toppings = ["Cheese", "Tomato", "Pepperoni", "Mushrooms", "Olives", "Jalapeños"]

# Start with Cheese and Pepperoni pre-selected
topping_state = Ref(MultiSelectState(length(toppings); selected_indices=Set([1, 3])))

function MyApp()
    Card(
        "Pizza toppings:",
        MultiSelectList(
            toppings,
            topping_state[];
            on_state_change=(new_state) -> topping_state[] = new_state,
            on_change=(selected) -> println("Toppings: ", sort(collect(selected))),
        )
    )
end

screenshot(MyApp, "multi_select_preselected.png", 400, 250);
nothing #hide
```

![Pre-selected MultiSelectList](multi_select_preselected.png)

## Dark Theme

```@example MultiSelectList
fruits = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"]
toppings = ["Cheese", "Tomato", "Pepperoni", "Mushrooms", "Olives", "Jalapeños"]

fruit_state = Ref(MultiSelectState(length(fruits)))
topping_state = Ref(MultiSelectState(length(toppings); selected_indices=Set([1, 3])))

dark_card_style = ContainerStyle(
    background_color=Vec4{Float32}(0.15f0, 0.15f0, 0.18f0, 1.0f0),
    border_color=Vec4{Float32}(0.25f0, 0.25f0, 0.30f0, 1.0f0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0,
)
dark_title_style = TextStyle(size_points=16, color=Vec4{Float32}(0.9f0, 0.9f0, 0.95f0, 1.0f0))
dark_text_style  = TextStyle(size_points=14, color=Vec4{Float32}(0.85f0, 0.85f0, 0.90f0, 1.0f0))

blue_style = MultiSelectListStyle(
    item_height=28.0f0,
    text_style=dark_text_style,
    item_background=Vec4{Float32}(0.10f0, 0.10f0, 0.13f0, 1.0f0),
    item_hover_color=Vec4{Float32}(0.20f0, 0.22f0, 0.30f0, 1.0f0),
    item_selected_color=Vec4{Float32}(0.22f0, 0.45f0, 0.80f0, 1.0f0),
    item_selected_hover_color=Vec4{Float32}(0.28f0, 0.52f0, 0.88f0, 1.0f0),
    border_color=Vec4{Float32}(0.25f0, 0.25f0, 0.30f0, 1.0f0),
)

green_style = MultiSelectListStyle(
    item_height=30.0f0,
    text_style=dark_text_style,
    item_background=Vec4{Float32}(0.10f0, 0.10f0, 0.13f0, 1.0f0),
    item_hover_color=Vec4{Float32}(0.12f0, 0.22f0, 0.14f0, 1.0f0),
    item_selected_color=Vec4{Float32}(0.10f0, 0.50f0, 0.22f0, 1.0f0),
    item_selected_hover_color=Vec4{Float32}(0.14f0, 0.58f0, 0.28f0, 1.0f0),
    border_color=Vec4{Float32}(0.25f0, 0.25f0, 0.30f0, 1.0f0),
)

function MyApp()
    Container(
        IntrinsicColumn([
                Card("Fruit selection:",
                    MultiSelectList(
                        fruits, fruit_state[];
                        style=blue_style,
                        on_state_change=(s) -> fruit_state[] = s,
                        on_change=(sel) -> println("Fruits: ", sort(collect(sel))),
                    );
                    style=dark_card_style, title_style=dark_title_style,
                ),
                Card("Pizza toppings (pre-selected):",
                    MultiSelectList(
                        toppings, topping_state[];
                        style=green_style,
                        on_state_change=(s) -> topping_state[] = s,
                        on_change=(sel) -> println("Toppings: ", sort(collect(sel))),
                    );
                    style=dark_card_style, title_style=dark_title_style,
                ),
            ],
            spacing=0
        );
        style=ContainerStyle(
            background_color=Vec4{Float32}(0.08f0, 0.08f0, 0.10f0, 1.0f0),
            border_width=0.0f0, padding=0.0f0, corner_radius=0.0f0,
        )
    )
end

screenshot(MyApp, "multi_select_dark.png", 400, 500);
nothing #hide
```

![Dark MultiSelectList](multi_select_dark.png)

## Scrollable Long List

Wrap in a `VerticalScrollArea` and `FixedHeight` to make a long list scrollable.

```@example MultiSelectList
long_options = ["Option $i" for i in 1:20]
long_state   = Ref(MultiSelectState(length(long_options)))
scroll_state = Ref(VerticalScrollState())

dark_card_style = ContainerStyle(
    background_color=Vec4{Float32}(0.15f0, 0.15f0, 0.18f0, 1.0f0),
    border_color=Vec4{Float32}(0.25f0, 0.25f0, 0.30f0, 1.0f0),
    border_width=1.5f0, padding=12.0f0, corner_radius=6.0f0,
)
dark_title_style = TextStyle(size_points=16, color=Vec4{Float32}(0.9f0, 0.9f0, 0.95f0, 1.0f0))
dark_text_style  = TextStyle(size_points=14, color=Vec4{Float32}(0.85f0, 0.85f0, 0.90f0, 1.0f0))

list_style = MultiSelectListStyle(
    item_height=28.0f0,
    text_style=dark_text_style,
    item_background=Vec4{Float32}(0.10f0, 0.10f0, 0.13f0, 1.0f0),
    item_hover_color=Vec4{Float32}(0.20f0, 0.22f0, 0.30f0, 1.0f0),
    item_selected_color=Vec4{Float32}(0.22f0, 0.45f0, 0.80f0, 1.0f0),
    item_selected_hover_color=Vec4{Float32}(0.28f0, 0.52f0, 0.88f0, 1.0f0),
    border_color=Vec4{Float32}(0.25f0, 0.25f0, 0.30f0, 1.0f0),
)

function MyApp()
    Container(
        Card("Long list in a scroll area:",
            FixedHeight(
                VerticalScrollArea(
                    MultiSelectList(
                        long_options, long_state[];
                        style=list_style,
                        on_state_change=(s) -> long_state[] = s,
                        on_change=(sel) -> println("Selected: ", sort(collect(sel))),
                    );
                    scroll_state=scroll_state[],
                    on_scroll_change=(s) -> scroll_state[] = s,
                ),
                150.0f0
            );
            style=dark_card_style, title_style=dark_title_style,
        );
        style=ContainerStyle(
            background_color=Vec4{Float32}(0.08f0, 0.08f0, 0.10f0, 1.0f0),
            border_width=0.0f0, padding=0.0f0, corner_radius=0.0f0,
        )
    )
end

screenshot(MyApp, "multi_select_scroll.png", 400, 230);
nothing #hide
```

![Scrollable MultiSelectList](multi_select_scroll.png)
