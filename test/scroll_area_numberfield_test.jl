using Fugl
using Fugl: Text

# Parameter rows state - similar to your app structure
parameter_rows = Ref(Vector{Tuple{Ref{EditorState},Ref{EditorState}}}())

# Scroll state for the properties panel
properties_scroll_state = Ref(VerticalScrollState())

# Button state for adding parameters
add_parameter_button_state = Ref(InteractionState())

# Initialize with some test data
function initialize_test_data!()
    rows = Vector{Tuple{Ref{EditorState},Ref{EditorState}}}()

    # Add initial test parameters
    test_params = [
        ("Resistance", "100.0"),
        ("Capacitance", "0.001"),
        ("Inductance", "0.01"),
        ("Voltage", "5.0"),
        ("Current", "0.5"),
        ("Power", "2.5"),
        ("Frequency", "1000.0"),
        ("Temperature", "25.0"),
        ("Tolerance", "0.05"),
        ("Length", "10.0"),
    ]

    for (name, value) in test_params
        name_field = Ref(EditorState(name))
        value_field = Ref(EditorState(value))
        push!(rows, (name_field, value_field))
    end

    parameter_rows[] = rows
end

# Dark theme color palette
const DARK_BG_PRIMARY = Vec4f(0.15, 0.15, 0.18, 1.0)      # Main dark background
const DARK_BG_SECONDARY = Vec4f(0.08, 0.10, 0.14, 1.0)    # Darker background for inputs
const DARK_BG_TERTIARY = Vec4f(0.06, 0.08, 0.12, 1.0)     # Even darker for focused states
const DARK_BORDER = Vec4f(0.25, 0.25, 0.30, 1.0)          # Subtle borders
const DARK_TEXT = Vec4f(0.9, 0.9, 0.95, 1.0)              # Light text
const DARK_ACCENT_BLUE = Vec4f(0.4, 0.6, 0.9, 1.0)        # Blue accent

# Dark theme card style (for reuse across app)
card_style = ContainerStyle(
    background_color=DARK_BG_PRIMARY,
    border_color=DARK_BORDER,
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0,
    anti_aliasing_width=1.0f0
)

# Dark theme card title style
card_title_style = TextStyle(
    size_px=18,
    color=DARK_TEXT
)

scroll_style = Fugl.ScrollAreaStyle(
    scrollbar_width=4.0f0,
    scrollbar_color=Vec4f(0.4, 0.4, 0.45, 0.8),       # Slightly brighter for dark theme
    scrollbar_background_color=Vec4f(0.15, 0.15, 0.18, 0.3),  # Very transparent background
    scrollbar_hover_color=Vec4f(0.5, 0.5, 0.55, 0.8), # Brighter on hover
    corner_color=Vec4f(0.15, 0.15, 0.18, 0.3)         # Transparent corner
)

# Dark theme number field style
number_field_style = TextBoxStyle(
    background_color_unfocused=DARK_BG_SECONDARY,
    background_color_focused=DARK_BG_TERTIARY,
    border_color=DARK_BORDER,
    border_width=2.0f0,
    corner_radius=6.0f0,
    padding=8.0f0,
    cursor_color=Vec4f(1.0, 1.0, 1.0, 0.8),
    selection_color=Vec4f(0.4, 0.6, 0.9, 0.5),
    text_style=TextStyle(
        color=DARK_TEXT,
        size_px=14
    )
)

# Dark theme text field style
text_field_style = TextBoxStyle(
    background_color_unfocused=DARK_BG_SECONDARY,
    background_color_focused=DARK_BG_TERTIARY,
    border_color=DARK_BORDER,
    border_width=2.0f0,
    corner_radius=6.0f0,
    padding=8.0f0,
    cursor_color=Vec4f(1.0, 1.0, 1.0, 0.8),
    selection_color=Vec4f(0.4, 0.6, 0.9, 0.5),
    text_style=TextStyle(
        color=DARK_TEXT,
        size_px=14
    )
)

# Dark theme text style for labels
label_text_style = TextStyle(
    size_px=14,
    color=DARK_TEXT
)

# Dark button styles
inactive_button_style = ContainerStyle(
    background_color=Vec4f(0.20, 0.20, 0.23, 1.0),   # Dark gray for inactive
    border_color=DARK_BORDER,
    border_width=1.0f0,
    padding=8.0f0
)

button_text_style = TextStyle(
    color=DARK_TEXT,                                  # Light text
    size_px=14
)

function create_parameter_form()
    Card("Component Properties - NumberField Scroll Test",
        IntrinsicColumn([
                # Header information
                IntrinsicHeight(Fugl.Text("Simulation Parameters:"; style=label_text_style)),

                # Scroll area with parameter rows
                VerticalScrollArea(
                    IntrinsicColumn([
                            # Dynamic parameter rows
                            [IntrinsicHeight(
                                IntrinsicRow([
                                        FixedWidth(
                                            Fugl.Text("Name:"; style=label_text_style),
                                            60.0f0
                                        ),
                                        FixedWidth(
                                            TextField(
                                                name_ref[];
                                                style=text_field_style,
                                                on_state_change=(new_state) -> begin
                                                    name_ref[] = new_state
                                                    println("Parameter name changed to: $(new_state.text)")
                                                end
                                            ),
                                            120.0f0
                                        ),
                                        FixedWidth(
                                            Fugl.Text("Value:"; style=label_text_style),
                                            60.0f0
                                        ),
                                        FixedWidth(
                                            NumberField(
                                                value_ref[];
                                                type=Float32,
                                                style=number_field_style,
                                                on_state_change=(new_state) -> begin
                                                    value_ref[] = new_state
                                                    println("Parameter value changed to: $(new_state.text)")
                                                end,
                                                on_change=(new_value) -> begin
                                                    println("Parameter value parsed to: $(new_value) ($(typeof(new_value)))")
                                                end
                                            ),
                                            100.0f0
                                        )
                                    ]; spacing=5.0f0)
                            ) for (name_ref, value_ref) in parameter_rows[]]...
                        ]; spacing=3.0f0),
                    scroll_state=properties_scroll_state[],
                    style=scroll_style,
                    show_scrollbar=true,
                    on_scroll_change=(new_state) -> begin
                        properties_scroll_state[] = new_state
                        println("Scroll position: $(new_state.scroll_offset)")
                    end
                ),

                # Add parameter button
                IntrinsicHeight(
                    IntrinsicRow([
                            FixedWidth(
                                TextButton(
                                    "Add Parameter";
                                    on_click=() -> begin
                                        # Add a new empty parameter row
                                        new_name_field = Ref(EditorState("new_param"))
                                        new_value_field = Ref(EditorState("0.0"))
                                        # Create a new vector with the additional row to trigger re-rendering
                                        updated_rows = copy(parameter_rows[])
                                        push!(updated_rows, (new_name_field, new_value_field))
                                        parameter_rows[] = updated_rows
                                        println("Added new parameter row. Total rows: $(length(updated_rows))")
                                    end,
                                    interaction_state=add_parameter_button_state[],
                                    on_interaction_state_change=(new_state) -> add_parameter_button_state[] = new_state
                                ),
                                120.0f0
                            ),
                            FixedWidth(
                                TextButton(
                                    "Clear All";
                                    on_click=() -> begin
                                        parameter_rows[] = Vector{Tuple{Ref{EditorState},Ref{EditorState}}}()
                                        println("Cleared all parameters")
                                    end
                                ),
                                80.0f0
                            ),
                            FixedWidth(
                                TextButton(
                                    "Reset Test Data";
                                    on_click=() -> begin
                                        initialize_test_data!()
                                        println("Reset to test data")
                                    end
                                ),
                                120.0f0
                            )
                        ]; spacing=10.0f0)
                ),

                # Debug information
                IntrinsicHeight(Fugl.Text("Total Parameters: $(length(parameter_rows[]))"; style=label_text_style))
            ]; spacing=10.0f0);
        style=card_style,
        title_style=card_title_style
    )
end

function test_scroll_area_numberfields()
    create_parameter_form()
end

# Initialize test data before running
initialize_test_data!()

# Run the test
Fugl.run(test_scroll_area_numberfields,
    title="Scroll Area NumberField Test - Troubleshooting",
    window_width_px=700,
    window_height_px=600,
    fps_overlay=true
)