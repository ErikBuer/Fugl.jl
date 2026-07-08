# Tabs

## Basic Usage

The Tabs component requires user-managed state to track the selected tab index.

```@example Tabs
using Fugl

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

screenshot(MyApp, "tabs_basic.png", 500, 200);
nothing #hide
```

![Basic Tabs](tabs_basic.png)

## Dark Mode Example

A dark-themed tabs interface using border color to indicate selection.

```@example Tabs

selected_tab_dark = Ref(1)

# Dark background colors
main_bg = Vec4{Float32}(0.12f0, 0.12f0, 0.12f0, 1.0f0)
tab_area_bg = Vec4{Float32}(0.16f0, 0.16f0, 0.16f0, 1.0f0)
tab_bg_color = Vec4{Float32}(0.18f0, 0.18f0, 0.18f0, 1.0f0)
selected_border = Vec4{Float32}(0.3f0, 0.6f0, 0.95f0, 1.0f0)
unselected_border = Vec4{Float32}(0.25f0, 0.25f0, 0.25f0, 1.0f0)

function MyApp()
    Container(
        Column([
            Fugl.Text("Dark Theme Tabs"; style=TextStyle(size_points=22, color=Vec4{Float32}(0.95f0, 0.95f0, 0.95f0, 1.0f0))),
            Container(
                Tabs(
                    [
                        ("Overview", Fugl.Text("Content of overview tab"; style=TextStyle(color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0)))),
                        ("Settings", Fugl.Text("Content of settings tab"; style=TextStyle(color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0)))),
                        ("About", Fugl.Text("Content of about tab"; style=TextStyle(color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0))))
                    ];
                    selected_index=selected_tab_dark[],
                    on_tab_change=(index) -> selected_tab_dark[] = index,
                    style=TabsStyle(tab_height=38.0f0),
                    normal_style=TabStyle(
                        background_color=tab_bg_color,
                        border_color=unselected_border,
                        border_width=2.0f0,
                        corner_radius=6.0f0,
                    ),
                    selected_style=TabStyle(
                        background_color=tab_bg_color,
                        border_color=selected_border,
                        border_width=2.0f0,
                        corner_radius=6.0f0,
                        text_style=TextStyle(size_points=14, color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0)),
                    ),
                );
                style=ContainerStyle(
                    background_color=tab_area_bg,
                    padding=8.0f0,
                    corner_radius=8.0f0
                )
            )
        ]);
        style=ContainerStyle(background_color=main_bg)
    )
end

screenshot(MyApp, "tabs_dark.png", 600, 300);
nothing #hide
```

![Dark Mode Tabs](tabs_dark.png)

## Tab Corner Radius

Customize the appearance of tabs with rounded corners.

```@example Tabs

tab_state1 = Ref(1)
tab_state2 = Ref(1)

function MyApp()
    Container(
        Column([
            Fugl.Text("No rounded corners"; style=TextStyle(size_points=14)),
            Tabs(
                [
                    ("Tab 1", Fugl.Text("Content 1")),
                    ("Tab 2", Fugl.Text("Content 2")),
                    ("Tab 3", Fugl.Text("Content 3"))
                ];
                selected_index=tab_state1[],
                on_tab_change=(i) -> tab_state1[] = i,
                normal_style=TabStyle(corner_radius=0.0f0),
                selected_style=TabStyle(
                    background_color=Vec4{Float32}(0.2f0, 0.4f0, 0.7f0, 1.0f0),
                    border_color=Vec4{Float32}(0.3f0, 0.6f0, 0.9f0, 1.0f0),
                    corner_radius=0.0f0,
                    text_style=TextStyle(size_points=14, color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0)),
                ),
            ),
            Fugl.Text("Rounded corners (12px)"; style=TextStyle(size_points=14)),
            Tabs(
                [
                    ("Tab 1", Fugl.Text("Content 1")),
                    ("Tab 2", Fugl.Text("Content 2")),
                    ("Tab 3", Fugl.Text("Content 3"))
                ];
                selected_index=tab_state2[],
                on_tab_change=(i) -> tab_state2[] = i,
                normal_style=TabStyle(corner_radius=12.0f0),
                selected_style=TabStyle(
                    background_color=Vec4{Float32}(0.2f0, 0.4f0, 0.7f0, 1.0f0),
                    border_color=Vec4{Float32}(0.3f0, 0.6f0, 0.9f0, 1.0f0),
                    corner_radius=12.0f0,
                    text_style=TextStyle(size_points=14, color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0)),
                ),
            )
        ])
    )
end

screenshot(MyApp, "tabs_corners.png", 600, 250);
nothing #hide
```

![Tab Corner Radius](tabs_corners.png)

## Text Style Customization

Customize the appearance of tab text.

```@example Tabs

tab_custom = Ref(2)

custom_text = TextStyle(size_points=16, color=Vec4{Float32}(0.6f0, 0.6f0, 0.6f0, 1.0f0))
custom_selected = TextStyle(size_points=16, color=Vec4{Float32}(1.0f0, 0.9f0, 0.5f0, 1.0f0))

function MyApp()
    Tabs(
        [
            ("Home", Fugl.Text("Home page content")),
            ("Profile", Fugl.Text("User profile")),
            ("Settings", Fugl.Text("Application settings"))
        ];
        selected_index=tab_custom[],
        on_tab_change=(i) -> tab_custom[] = i,
        style=TabsStyle(tab_height=45.0f0),
        normal_style=TabStyle(
            background_color=Vec4{Float32}(0.15f0, 0.15f0, 0.15f0, 1.0f0),
            corner_radius=8.0f0,
            text_style=custom_text,
        ),
        selected_style=TabStyle(
            background_color=Vec4{Float32}(0.2f0, 0.2f0, 0.25f0, 1.0f0),
            corner_radius=8.0f0,
            text_style=custom_selected,
        ),
    )
end

screenshot(MyApp, "tabs_text.png", 600, 200);
nothing #hide
```

![Tab Text Style](tabs_text.png)

## Hover Style

`hover_style` is applied to unselected tabs when the cursor is over them, giving visual feedback before clicking.

```@example Tabs

tab_hover = Ref(1)

function MyApp()
    Tabs(
        [
            ("Home",     Fugl.Text("Home page content")),
            ("Profile",  Fugl.Text("User profile")),
            ("Settings", Fugl.Text("Application settings"))
        ];
        selected_index=tab_hover[],
        on_tab_change=(i) -> tab_hover[] = i,
        style=TabsStyle(tab_height=40.0f0),
        normal_style=TabStyle(
            background_color=Vec4{Float32}(0.15f0, 0.15f0, 0.15f0, 1.0f0),
            border_color=Vec4{Float32}(0.25f0, 0.25f0, 0.25f0, 1.0f0),
            border_width=2.0f0,
            corner_radius=6.0f0,
        ),
        selected_style=TabStyle(
            background_color=Vec4{Float32}(0.18f0, 0.18f0, 0.18f0, 1.0f0),
            border_color=Vec4{Float32}(0.3f0, 0.6f0, 0.95f0, 1.0f0),
            border_width=2.0f0,
            corner_radius=6.0f0,
            text_style=TextStyle(size_points=14, color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0)),
        ),
        hover_style=TabStyle(
            background_color=Vec4{Float32}(0.22f0, 0.22f0, 0.22f0, 1.0f0),
            border_color=Vec4{Float32}(0.40f0, 0.40f0, 0.40f0, 1.0f0),
            border_width=2.0f0,
            corner_radius=6.0f0,
            text_style=TextStyle(size_points=14, color=Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0)),
        ),
    )
end

screenshot(MyApp, "tabs_hover.png", 600, 200);
nothing #hide
```

![Hover Style](tabs_hover.png)

## Fixed Width Tabs

Tabs can have fixed or flexible widths. Use `NaN32` for flexible tabs that share space equally, or specify a width in pixels for fixed-width tabs. This is useful for creating special tabs like "add new" buttons.

```@example Tabs



selected_tab_fixed = Ref(1)
tab_list = Ref([
    ("Tab 1", Fugl.Text("First tab content"; style=TextStyle(color=Vec4{Float32}(0.7f0, 0.7f0, 0.7f0, 1.0f0))), NaN32),
    ("Tab 2", Fugl.Text("Second tab content"; style=TextStyle(color=Vec4{Float32}(0.7f0, 0.7f0, 0.7f0, 1.0f0))), NaN32),
    ("+", Empty(), 40.0f0)
])

function MyApp()
    # Handle tab clicks
    on_tab_click = (index) -> begin
        if index == length(tab_list[])  # Clicked the "+" tab
            # Add a new tab before the "+" tab
            new_tab_num = length(tab_list[]) 
            new_tab = ("Tab $new_tab_num", Fugl.Text("Content $new_tab_num"; style=TextStyle(color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0))), NaN32)
            # Insert before the "+" tab
            tab_list[] = vcat(tab_list[][1:end-1], [new_tab], [tab_list[][end]])
            selected_tab_fixed[] = new_tab_num
        else
            selected_tab_fixed[] = index
        end
    end
    
    Container(
        Column([
            Fugl.Text("Click + to add new tabs"; style=TextStyle(size_points=14, color=Vec4{Float32}(0.7f0, 0.7f0, 0.7f0, 1.0f0))),
            Tabs(
                tab_list[];
                selected_index=selected_tab_fixed[],
                on_tab_change=on_tab_click,
                style=TabsStyle(tab_height=38.0f0),
                normal_style=TabStyle(
                    background_color=Vec4{Float32}(0.18f0, 0.18f0, 0.18f0, 1.0f0),
                    border_color=Vec4{Float32}(0.25f0, 0.25f0, 0.25f0, 1.0f0),
                    border_width=1.5f0,
                    corner_radius=6.0f0,
                ),
                selected_style=TabStyle(
                    background_color=Vec4{Float32}(0.25f0, 0.45f0, 0.75f0, 1.0f0),
                    border_color=Vec4{Float32}(0.4f0, 0.6f0, 0.9f0, 1.0f0),
                    border_width=1.5f0,
                    corner_radius=6.0f0,
                    text_style=TextStyle(size_points=14, color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0)),
                ),
            )
        ]);
        style=ContainerStyle(
            background_color=Vec4{Float32}(0.12f0, 0.12f0, 0.12f0, 1.0f0),
            padding=10.0f0
        )
    )
end

screenshot(MyApp, "tabs_fixed_width.png", 600, 200);
nothing #hide
```

![Fixed Width Tabs](tabs_fixed_width.png)
