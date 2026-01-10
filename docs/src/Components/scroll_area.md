# ScrollArea

The `ScrollArea` component provides scrollable containers for content that exceeds the available viewport size. It supports both vertical and horizontal scrolling with customizable scrollbar styling.

## Basic Vertical ScrollArea

```@example scroll_basic
using Fugl
using Fugl: VerticalScrollArea, Table, TableStyle, TextStyle, Card, VerticalScrollState, ScrollAreaStyle, ContainerStyle

function MyApp()
    # Create large content that needs scrolling
    headers = ["ID", "Name", "Value", "Category"]
    data = Vector{Vector{String}}()

    for i in 1:30
        push!(data, [
            string(i),
            "Item $i",
            "Value $(i * 10)",
            "Category $(i % 5 + 1)"
        ])
    end

    # Create table as scrollable content
    table = Table(
        headers,
        data,
        style=TableStyle(
            header_background_color=Vec4f(0.25, 0.35, 0.55, 1.0),
            header_text_style=TextStyle(size_px=14, color=Vec4f(0.9, 0.9, 0.9, 1.0)),
            cell_background_color=Vec4f(0.15, 0.15, 0.15, 1.0),
            cell_alternate_background_color=Vec4f(0.18, 0.18, 0.18, 1.0),
            cell_text_style=TextStyle(size_px=12, color=Vec4f(0.85, 0.85, 0.85, 1.0)),
            show_grid=true,
            grid_color=Vec4f(0.4, 0.4, 0.4, 1.0),
            cell_padding=8.0f0
        )
    )

    scroll_state = Ref(VerticalScrollState())

    # Dark theme card style
    dark_card_style = ContainerStyle(
        background_color=Vec4f(0.18, 0.18, 0.22, 1.0),
        border_color=Vec4f(0.4, 0.4, 0.45, 1.0),
        border_width=1.5f0,
        corner_radius=8.0f0,
        padding=15.0f0
    )

    dark_title_style = TextStyle(
        size_px=18,
        color=Vec4f(0.9, 0.9, 0.95, 1.0)
    )

    Card(
        "Basic Vertical ScrollArea",
        VerticalScrollArea(
            table,
            scroll_state=scroll_state[],
            on_scroll_change=(new_state) -> scroll_state[] = new_state
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyApp, "scroll_basic.png", 812, 400)
nothing # hide
```

![Basic ScrollArea](scroll_basic.png)

## Interactive ScrollArea with Table

```@example scroll_interactive
using Fugl
using Fugl: VerticalScrollArea, Table, TableStyle, TextStyle, Card, VerticalScrollState, ScrollAreaStyle, ContainerStyle

function MyApp()
    # Create interactive table data
    headers = ["ID", "Name", "Value"]
    data = Vector{Vector{String}}()

    for i in 1:50
        push!(data, [
            string(i),
            "Item $i",
            "Value $(i * 10)"
        ])
    end

    # Create interactive table
    table = Table(
        headers,
        data,
        style=TableStyle(
            header_background_color=Vec4f(0.25, 0.35, 0.55, 1.0),
            header_text_style=TextStyle(size_px=14, color=Vec4f(0.9, 0.9, 0.9, 1.0)),
            header_height=30.0f0,
            cell_background_color=Vec4f(0.15, 0.15, 0.15, 1.0),
            cell_alternate_background_color=Vec4f(0.18, 0.18, 0.18, 1.0),
            cell_text_style=TextStyle(size_px=12, color=Vec4f(0.85, 0.85, 0.85, 1.0)),
            cell_height=25.0f0,
            show_grid=true,
            grid_color=Vec4f(0.4, 0.4, 0.4, 1.0),
            cell_padding=6.0f0
        ),
        on_cell_click=(row, col) -> begin
            if row <= length(data) && col <= length(headers)
                println("Clicked row $row ($(headers[col])): $(data[row][col])")
            end
        end
    )

    scroll_state = Ref(VerticalScrollState())

    # Dark scrollbar style
    scroll_style = ScrollAreaStyle(
        scrollbar_width=4.0f0,
        scrollbar_color=Vec4f(0.55, 0.65, 0.75, 0.8),
        scrollbar_background_color=Vec4f(0.2, 0.2, 0.2, 0.3),
        scrollbar_hover_color=Vec4f(0.65, 0.75, 0.85, 0.9),
        corner_color=Vec4f(0.2, 0.2, 0.2, 0.3)
    )

    # Dark theme card style
    dark_card_style = ContainerStyle(
        background_color=Vec4f(0.18, 0.18, 0.22, 1.0),
        border_color=Vec4f(0.4, 0.4, 0.45, 1.0),
        border_width=1.5f0,
        corner_radius=8.0f0,
        padding=15.0f0
    )

    dark_title_style = TextStyle(
        size_px=18,
        color=Vec4f(0.9, 0.9, 0.95, 1.0)
    )

    Card(
        "Interactive ScrollArea - Use mouse wheel to scroll, click cells",
        VerticalScrollArea(
            table,
            scroll_state=scroll_state[],
            style=scroll_style,
            show_scrollbar=true,
            on_scroll_change=(new_state) -> scroll_state[] = new_state,
            on_click=(x, y) -> println("Clicked in scroll area at: ($x, $y)")
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyApp, "scroll_interactive.png", 812, 500)
nothing # hide
```

![Interactive ScrollArea](scroll_interactive.png)

## Horizontal ScrollArea

```@example scroll_horizontal
using Fugl
using Fugl: HorizontalScrollArea, Row, Fugl.Text, TextStyle, Card, HorizontalScrollState, ScrollAreaStyle, Container, ContainerStyle

function MyApp()
    # Create wide content that needs horizontal scrolling
    wide_items = [
        Container(
            Fugl.Text("Item $i - This is a very long text that makes the content wide", 
                style=TextStyle(size_px=14, color=Vec4f(0.85, 0.85, 0.85, 1.0))),
            style=ContainerStyle(
                background_color=Vec4f(0.18, 0.22, 0.25, 1.0),
                border_color=Vec4f(0.35, 0.45, 0.55, 1.0),
                border_width=1.0f0,
                corner_radius=4.0f0,
                padding=10.0f0
            )
        )
        for i in 1:15
    ]

    wide_content = Row(wide_items, spacing=10.0f0, padding=5.0f0)

    scroll_state = Ref(HorizontalScrollState())

    # Dark horizontal scrollbar style
    scroll_style = ScrollAreaStyle(
        scrollbar_width=6.0f0,
        scrollbar_color=Vec4f(0.45, 0.65, 0.55, 0.8),
        scrollbar_background_color=Vec4f(0.15, 0.2, 0.18, 0.5),
        scrollbar_hover_color=Vec4f(0.55, 0.75, 0.65, 1.0),
        corner_color=Vec4f(0.15, 0.2, 0.18, 0.8)
    )

    # Dark theme card style
    dark_card_style = ContainerStyle(
        background_color=Vec4f(0.18, 0.18, 0.22, 1.0),
        border_color=Vec4f(0.4, 0.4, 0.45, 1.0),
        border_width=1.5f0,
        corner_radius=8.0f0,
        padding=15.0f0
    )

    dark_title_style = TextStyle(
        size_px=18,
        color=Vec4f(0.9, 0.9, 0.95, 1.0)
    )

    Card(
        "Horizontal ScrollArea - Use mouse wheel to scroll horizontally",
        HorizontalScrollArea(
            wide_content,
            scroll_state=scroll_state[],
            style=scroll_style,
            show_scrollbar=true,
            on_scroll_change=(new_state) -> scroll_state[] = new_state
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyApp, "scroll_horizontal.png", 812, 200)
nothing # hide
```

![Horizontal ScrollArea](scroll_horizontal.png)
