# Tooltip

The `Tooltip` component provides overlay tooltips that appear when hovering over wrapped components. It uses a wrapper pattern similar to the Modal component, making it easy to add tooltips to any component.

## Basic Tooltip

```@example tooltip_basic
using Fugl
using Fugl: Tooltip, TooltipStyle, Card

# Dark theme card style
dark_card_style = ContainerStyle(
    background_color = Vec4f(0.18, 0.18, 0.22, 1.0),  # Dark gray background
    border_color = Vec4f(0.4, 0.4, 0.45, 1.0),       # Subtle border
    border_width = 1.5f0,
    corner_radius = 0.0f0,
    padding = 15.0f0
)

# Dark theme title style
dark_title_style = TextStyle(
    size_points = 18,
    color = Vec4f(0.9, 0.9, 0.95, 1.0)  # Light text for title
)

# Persistent state (essential for timing-based tooltips)
tooltip_state = Ref(TooltipState(is_visible=true))

function MyApp()
    # Dark theme container
    Container(
        Card(
            "Basic Tooltip Demo",
            Container(
                IntrinsicColumn([
                    Fugl.Text("Hover over the button below to see a basic tooltip:", 
                         style=TextStyle(color=Vec4f(0.8, 0.8, 0.8, 1.0))),
                    
                    # Basic tooltip wrapping a button
                    Tooltip(
                        "This is a helpful tooltip!",
                        Container(
                            Fugl.Text("Hover Me", style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0))),
                            style=ContainerStyle(
                                background_color=Vec4f(0.2, 0.6, 0.9, 1.0),
                                padding=15.0f0,
                                corner_radius=8.0f0
                            )
                        ),
                        position=:top,
                        state=tooltip_state[],
                        on_state_change=(new_state) -> tooltip_state[] = new_state
                    )
                ], spacing=15.0f0),
                style=ContainerStyle(
                    background_color=Vec4f(0.15, 0.15, 0.15, 1.0),
                    padding=20.0f0
                )
            ),
            style=dark_card_style,
            title_style=dark_title_style
        )
    )
end

screenshot(MyApp, "tooltip_basic.png", 400, 200)
nothing # hide
```

![Basic Tooltip](tooltip_basic.png)

## Positioned Tooltips

```@example tooltip_positioning
using Fugl
using Fugl: Tooltip, TooltipStyle, Card

# Persistent states for each tooltip
tooltip1_state = Ref(TooltipState(is_visible=true))
tooltip2_state = Ref(TooltipState(is_visible=true)) 
tooltip3_state = Ref(TooltipState(is_visible=true))
tooltip4_state = Ref(TooltipState(is_visible=true))

# Button style for dark theme
button_style = ContainerStyle(
    background_color=Vec4f(0.3, 0.4, 0.6, 1.0),
    border_color=Vec4f(0.5, 0.6, 0.8, 1.0),
    border_width=1.0f0,
    padding=15.0f0,
    corner_radius=8.0f0
)

# Dark theme card style
dark_card_style = ContainerStyle(
    background_color = Vec4f(0.18, 0.18, 0.22, 1.0),  # Dark gray background
    border_color = Vec4f(0.4, 0.4, 0.45, 1.0),       # Subtle border
    border_width = 1.5f0,
    corner_radius = 0.0f0,
    padding = 15.0f0
)

# Dark theme title style
dark_title_style = TextStyle(
    size_points = 18,
    color = Vec4f(0.9, 0.9, 0.95, 1.0)  # Light text for title
)

function MyApp()
    Card(
        "Tooltip Positioning",
        Container(
            IntrinsicColumn([
                Fugl.Text("Tooltips can be positioned on different sides:", 
                        style=TextStyle(color=Vec4f(0.8, 0.8, 0.8, 1.0))),
                
                # Grid layout for positioning examples
                IntrinsicColumn([
                    Tooltip(
                        "I appear above!",
                        Container(
                            Fugl.Text("Top", style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0))),
                            style=button_style
                        ),
                        position=:top,
                        style=TooltipStyle(
                            background_color=Vec4f(0.8, 0.3, 0.3, 0.95),
                            text_style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0))
                        ),
                        state=tooltip1_state[],
                        on_state_change=(new_state) -> tooltip1_state[] = new_state
                    ),
                    
                    # Bottom tooltip
                    Tooltip(
                        "I appear below!",
                        Container(
                            Fugl.Text("Bottom", style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0))),
                            style=button_style
                        ),
                        position=:bottom,
                        style=TooltipStyle(
                            background_color=Vec4f(0.3, 0.3, 0.8, 0.95),
                            text_style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0))
                        ),
                        state=tooltip4_state[],
                        on_state_change=(new_state) -> tooltip4_state[] = new_state
                    )
                ], spacing=5.0f0)
            ], spacing=5.0f0),
            style=ContainerStyle(
                background_color=Vec4f(0.15, 0.15, 0.15, 1.0),
                padding=30.0f0
            )
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyApp, "tooltip_positioning.png", 600, 400)  
nothing # hide
```

![Positioned Tooltips](tooltip_positioning.png)

## Timing and Delay Customization

```@example tooltip_timing
using Fugl
using Fugl: Tooltip, TooltipStyle, Card

# Dark theme card style
dark_card_style = ContainerStyle(
    background_color = Vec4f(0.18, 0.18, 0.22, 1.0),  # Dark gray background
    border_color = Vec4f(0.4, 0.4, 0.45, 1.0),       # Subtle border
    border_width = 1.5f0,
    corner_radius = 0.0f0,
    padding = 15.0f0
)

# Dark theme title style
dark_title_style = TextStyle(
    size_points = 18,
    color = Vec4f(0.9, 0.9, 0.95, 1.0)  # Light text for title
)

# States with different timing
fast_tooltip_state = Ref(TooltipState(is_visible=true, show_delay=0.1, hide_delay=0.1))
slow_tooltip_state = Ref(TooltipState(is_visible=true, show_delay=1.0, hide_delay=0.5))

function MyApp()
    Card(
        "Tooltip Timing Control",
        Container(
            IntrinsicColumn([
                Fugl.Text("Tooltip show and hide delays can be customized:", 
                        style=TextStyle(color=Vec4f(0.8, 0.8, 0.8, 1.0))),
                
                IntrinsicRow([
                    # Fast tooltip
                    Tooltip(
                        "I appear quickly (0.1s) and hide quickly too!",
                        Container(
                            Fugl.Text("Fast Tooltip", style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0))),
                            style=ContainerStyle(
                                background_color=Vec4f(0.8, 0.4, 0.2, 1.0),
                                padding=15.0f0,
                                corner_radius=6.0f0
                            )
                        ),
                        style=TooltipStyle(
                            width=200.0f0,
                            background_color=Vec4f(0.9, 0.5, 0.2, 0.95),
                            text_style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0))
                        ),
                        position=:top,
                        state=fast_tooltip_state[],
                        on_state_change=(new_state) -> fast_tooltip_state[] = new_state
                    ),
                    
                    # Slow tooltip  
                    Tooltip(
                        "I take a full second to appear (1.0s show delay) but hide after 0.5s.",
                        Container(
                            Fugl.Text("Slow Tooltip", style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0))),
                            style=ContainerStyle(
                                background_color=Vec4f(0.2, 0.4, 0.8, 1.0),
                                padding=15.0f0,
                                corner_radius=6.0f0
                            )
                        ),
                        style=TooltipStyle(
                            width=220.0f0,
                            background_color=Vec4f(0.2, 0.5, 0.9, 0.95),
                            text_style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0))
                        ),
                        position=:top,
                        state=slow_tooltip_state[],
                        on_state_change=(new_state) -> slow_tooltip_state[] = new_state
                    )
                ], spacing=50.0f0)
            ], spacing=20.0f0),
            style=ContainerStyle(
                background_color=Vec4f(0.15, 0.15, 0.15, 1.0),
                padding=30.0f0
            )
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyApp, "tooltip_timing.png", 600, 300)
nothing # hide
```

![Tooltip Timing](tooltip_timing.png)
