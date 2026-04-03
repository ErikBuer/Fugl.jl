using Fugl
using Fugl: Text  # Explicitly import Text to avoid ambiguity

tooltip_state1 = Ref(TooltipState())
tooltip_state2 = Ref(TooltipState())
tooltip_state3 = Ref(TooltipState())


# Example demonstrating the new wrapper-style tooltip functionality
function tooltip_demo_new()
    # Define styles
    button_style = ContainerStyle(
        background_color=Vec4f(0.2, 0.6, 0.9, 1.0),
        border_color=Vec4f(0.1, 0.1, 0.1, 1.0),
        border_width=1.0f0,
        padding=15.0f0,
        corner_radius=8.0f0
    )

    # Different tooltip styles
    standard_tooltip_style = TooltipStyle(width=200.0f0)

    wide_tooltip_style = TooltipStyle(
        width=350.0f0,
        background_color=Vec4f(0.1, 0.1, 0.2, 0.95),
        text_style=TextStyle(color=Vec4f(0.9, 0.9, 1.0, 1.0), size_points=13.0f0),
        border_color=Vec4f(0.4, 0.4, 0.7, 1.0),
        corner_radius=10.0f0,
        padding=12.0f0
    )

    narrow_tooltip_style = TooltipStyle(
        width=150.0f0,
        background_color=Vec4f(0.2, 0.6, 0.2, 0.9),
        text_style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0), size_points=11.0f0),
        border_color=Vec4f(0.1, 0.4, 0.1, 1.0)
    )

    Container(
        IntrinsicColumn([
                # Title
                Container(
                    Text("New Tooltip Demo - Wrapper Style", style=TextStyle(size_points=24.0f0)),
                    style=ContainerStyle(padding=20.0f0)
                ),

                # Tooltip examples - much simpler now!
                IntrinsicColumn([
                        # Example 1: Simple tooltip
                        Tooltip(
                            "This is a simple tooltip that appears when hovering!",
                            Container(
                                Text("Hover for simple tooltip"),
                                style=button_style
                            ),
                            style=standard_tooltip_style,
                            state=tooltip_state1[],
                            on_state_change=(new_state) -> tooltip_state1[] = new_state
                        ),

                        # Example 2: Wide tooltip with text wrapping
                        Tooltip(
                            "This is a much longer tooltip text that demonstrates text wrapping functionality. When text exceeds the specified width, it will automatically wrap to new lines to fit within the tooltip bounds.",
                            Container(
                                Text("Hover for wrapping tooltip"),
                                style=button_style
                            ),
                            style=wide_tooltip_style,
                            state=tooltip_state2[],
                            on_state_change=(new_state) -> tooltip_state2[] = new_state
                        ),

                        # Example 3: Narrow tooltip
                        Tooltip(
                            "Narrow tooltip with lots of text wrapping because the width is constrained",
                            Container(
                                Text("Hover for narrow tooltip"),
                                style=button_style
                            ),
                            style=narrow_tooltip_style,
                            state=tooltip_state3[],
                            on_state_change=(new_state) -> tooltip_state3[] = new_state
                        ),

                        # Example 4: Tooltip on a text element
                        Tooltip(
                            "You can add tooltips to any component, including plain text!",
                            Text("This text has a tooltip - hover me!",
                                style=TextStyle(color=Vec4f(0.2, 0.2, 0.8, 1.0))),
                            style=TooltipStyle(width=250.0f0)
                        )
                    ], spacing=20.0f0),

                # Instructions
                Container(
                    Text(
                        "Instructions:\\n• Hover over any component to see its tooltip\\n• Tooltips automatically position next to components\\n• Much simpler API - just wrap any component!",
                        style=TextStyle(size_points=14.0f0)
                    ),
                    style=ContainerStyle(
                        background_color=Vec4f(0.95, 0.95, 0.95, 1.0),
                        padding=15.0f0,
                        corner_radius=5.0f0
                    )
                )
            ], spacing=15.0f0),
        style=ContainerStyle(
            background_color=Vec4f(0.98, 0.98, 1.0, 1.0),
            padding=30.0f0
        )
    )
end

# Run the demo 
Fugl.run(tooltip_demo_new, title="New Tooltip API Demo", window_width_points=900, window_height_points=700)