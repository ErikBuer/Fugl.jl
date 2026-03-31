using Fugl
using Fugl: Text, TextStyle, Container, FixedSize, Column, Row, TextButton, ContainerStyle, InteractionState

function test_dpi_scaling()
    # Create a DPI scaling reference for the app
    dpi_ref = create_dpi_scaling_ref()

    # Button interaction states
    smaller_button_state = Ref(InteractionState())
    larger_button_state = Ref(InteractionState())
    reset_button_state = Ref(InteractionState())

    # Button styles for debugging hover behavior
    normal_style = ContainerStyle(
        background_color=Vec4f(0.2, 0.4, 0.8, 1.0),
        border_color=Vec4f(0.1, 0.3, 0.7, 1.0),
        border_width=2.0f0,
        padding=12.0f0,
        corner_radius=6.0f0
    )

    hover_style = ContainerStyle(
        background_color=Vec4f(0.3, 0.5, 0.9, 1.0),  # Lighter blue on hover
        border_color=Vec4f(0.2, 0.4, 0.8, 1.0),
        border_width=2.0f0,
        padding=12.0f0,
        corner_radius=6.0f0
    )

    pressed_style = ContainerStyle(
        background_color=Vec4f(0.1, 0.2, 0.6, 1.0),  # Darker blue when pressed
        border_color=Vec4f(0.05, 0.15, 0.5, 1.0),
        border_width=2.0f0,
        padding=12.0f0,
        corner_radius=6.0f0
    )

    button_text_style = TextStyle(
        color=Vec4f(1.0, 1.0, 1.0, 1.0),  # White text
        size_points=14
    )

    function TestApp()
        # Get scaling values fresh each time the UI is rendered
        dpi_scale = get_effective_scale(dpi_ref)
        manual_scale = get_manual_scaling(dpi_ref)
        system_dpi_ratio = get_system_dpi_ratio(dpi_ref)
        pixel_perfect_scale = get_pixel_perfect_scale(dpi_ref)

        # Get window and framebuffer sizes for display
        logical_size = get_logical_size(dpi_ref)
        pixel_size = get_pixel_size(dpi_ref)

        # Create the UI content with fresh values
        ui_content = Column([
                Container(
                    Text("DPI Scaling Test (Projection Matrix Based)", style=TextStyle(size_points=24)),
                ),
                Container(
                    Text("Window: $(Int(logical_size[1]))×$(Int(logical_size[2])) pts | Framebuffer: $(Int(pixel_size[1]))×$(Int(pixel_size[2])) px",
                        style=TextStyle(size_points=10)),
                ),
                Container(
                    Text("System DPI ratio: $(round(system_dpi_ratio, digits=2))x (pixels per point)",
                        style=TextStyle(size_points=12, color=Vec4f(1.0, 0.8, 0.2, 1.0))),
                ),
                Container(
                    Text("Manual Scale: $(round(manual_scale, digits=2))x | Effective: $(round(pixel_perfect_scale, digits=3))x",
                        style=TextStyle(size_points=12, color=Vec4f(0.8, 1.0, 0.8, 1.0))),
                ),
                Container(
                    Text("Vector graphics scale via projection matrix, text renders at high-res",
                        style=TextStyle(size_points=10, color=Vec4f(0.7, 0.7, 1.0, 1.0))),
                ),
                Container(
                    Text("Normal Text (16px)", style=TextStyle(size_points=16)),
                ),
                Container(
                    Text("Large Text (32px)", style=TextStyle(size_points=32)),
                ),
                FixedSize(
                    Container(
                        Text("Fixed 300x150 Box\n(Fugl Points)", style=TextStyle(size_points=14)),
                    ),
                    300f0, 150f0
                ),
                Container(
                    Row([
                            TextButton("- Smaller",
                                on_click=() -> (
                                    adjust_manual_scaling!(-0.25f0);
                                    @info "Scaling decreased to $(round(get_manual_scaling(), digits=2))x"
                                ),
                                text_style=button_text_style,
                                container_style=normal_style,
                                hover_style=hover_style,
                                pressed_style=pressed_style,
                                interaction_state=smaller_button_state[],
                                on_interaction_state_change=(new_state) -> smaller_button_state[] = new_state
                            ),
                            Container(
                                Text("  Scale: $(round(manual_scale, digits=2))x  ", style=TextStyle(size_points=14)),
                            ),
                            TextButton("+ Larger",
                                on_click=() -> (
                                    adjust_manual_scaling!(0.25f0);
                                    @info "Scaling increased to $(round(get_manual_scaling(), digits=2))x"
                                ),
                                text_style=button_text_style,
                                container_style=normal_style,
                                hover_style=hover_style,
                                pressed_style=pressed_style,
                                interaction_state=larger_button_state[],
                                on_interaction_state_change=(new_state) -> larger_button_state[] = new_state
                            ),
                            TextButton("Reset 1x",
                                on_click=() -> (
                                    set_manual_scaling!(1.0f0);
                                    @info "Scaling reset to 1.0x"
                                ),
                                text_style=button_text_style,
                                container_style=normal_style,
                                hover_style=hover_style,
                                pressed_style=pressed_style,
                                interaction_state=reset_button_state[],
                                on_interaction_state_change=(new_state) -> reset_button_state[] = new_state
                            ),
                            TextButton("0.5x Test",
                                on_click=() -> (
                                    set_manual_scaling!(0.5f0);
                                    @info "Scaling set to 0.5x for testing"
                                ),
                                text_style=button_text_style,
                                container_style=normal_style,
                                hover_style=hover_style,
                                pressed_style=pressed_style,
                                interaction_state=reset_button_state[],  # Reuse reset button state
                                on_interaction_state_change=(new_state) -> reset_button_state[] = new_state
                            )
                        ], spacing=10)
                )
            ], spacing=0, padding=0)

        return ui_content
    end

    # Run with a reasonably sized window for testing
    # Pass the DPI scaling reference to the run function
    Fugl.run(TestApp,
        title="DPI Scaling Test - Click buttons to scale",
        window_width_points=800,
        window_height_points=700,
        dpi_scaling=dpi_ref
    )
end

test_dpi_scaling()