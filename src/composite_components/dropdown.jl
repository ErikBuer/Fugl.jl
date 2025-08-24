mutable struct DropdownStyle
    text_style::TextStyle
    background_color::Vec4{<:AbstractFloat}
    background_color_hover::Vec4{<:AbstractFloat}
    background_color_open::Vec4{<:AbstractFloat}
    border_color::Vec4{<:AbstractFloat}
    border_width::Float32
    corner_radius::Float32
    padding::Float32
    arrow_color::Vec4{<:AbstractFloat}
    item_height_px::Float32
    max_visible_items::Int
end

function DropdownStyle(;
    text_style=TextStyle(),
    background_color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0),        # White background
    background_color_hover=Vec4{Float32}(0.95f0, 0.95f0, 0.95f0, 1.0f0), # Light gray on hover
    background_color_open=Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0),     # Darker gray when open
    border_color=Vec4{Float32}(0.5f0, 0.5f0, 0.5f0, 1.0f0),
    border_width=1.0f0,
    corner_radius=8.0f0,
    padding=10.0f0,
    arrow_color=Vec4{Float32}(0.3f0, 0.3f0, 0.3f0, 1.0f0),
    item_height_px=30.0f0,
    max_visible_items=5
)
    return DropdownStyle(
        text_style, background_color, background_color_hover, background_color_open,
        border_color, border_width, corner_radius, padding, arrow_color,
        item_height_px, max_visible_items
    )
end

struct DropdownState
    options::Vector{String}      # Available options
    selected_index::Int          # Currently selected option (1-based, 0 = none selected)
    is_open::Bool               # Whether dropdown is expanded
    hover_index::Int            # Which item is being hovered (0 = none)
    is_hovered::Bool            # Whether the dropdown button itself is hovered
end

function DropdownState(
    options::Vector{String}=String[];
    selected_index::Int=0,
    is_open::Bool=false,
    hover_index::Int=0,
    is_hovered::Bool=false
)
    return DropdownState(options, selected_index, is_open, hover_index, is_hovered)
end

# Constructor to copy state with changes (like EditorState)
function DropdownState(state::DropdownState;
    options=state.options,
    selected_index=state.selected_index,
    is_open=state.is_open,
    hover_index=state.hover_index,
    is_hovered=state.is_hovered)
    return DropdownState(options, selected_index, is_open, hover_index, is_hovered)
end

struct DropdownView <: AbstractView
    state::DropdownState
    style::DropdownStyle
    on_state_change::Function    # Callback for state changes
    on_select::Function          # Callback when an option is selected
    placeholder_text::String
end

function Dropdown(
    state::DropdownState;
    style=DropdownStyle(),
    on_state_change::Function=(new_state) -> nothing,
    on_select::Function=(selected_value, selected_index) -> nothing,
    placeholder_text="Select option..."
)::DropdownView
    return DropdownView(state, style, on_state_change, on_select, placeholder_text)
end

function measure(view::DropdownView)::Tuple{Float32,Float32}
    # Always return just the button height - dropdown list overlays outside bounds
    button_height = view.style.text_style.size_px + 2 * view.style.padding
    return (Inf32, button_height)
end

function apply_layout(view::DropdownView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function interpret_view(view::DropdownView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Calculate button height
    button_height = view.style.text_style.size_px + 2 * view.style.padding

    # Draw the main dropdown button
    draw_dropdown_button(view, x, y, width, button_height, projection_matrix)

    # Draw the dropdown list if open
    if view.state.is_open
        dropdown_y = y + button_height
        visible_items = min(length(view.state.options), view.style.max_visible_items)
        dropdown_height = visible_items * view.style.item_height_px
        draw_dropdown_list(view, x, dropdown_y, width, dropdown_height, projection_matrix)
    end
end

function draw_dropdown_button(view::DropdownView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Choose background color based on state
    bg_color = if view.state.is_open
        view.style.background_color_open
    elseif view.state.is_hovered
        view.style.background_color_hover
    else
        view.style.background_color
    end

    # Draw button background
    vertex_positions = generate_rectangle_vertices(x, y, width, height)
    draw_rounded_rectangle(
        vertex_positions,
        width,
        height,
        bg_color,
        view.style.border_color,
        view.style.border_width,
        view.style.corner_radius,
        projection_matrix,
        1.5f0
    )

    # Draw selected text or placeholder
    display_text = if view.state.selected_index > 0 && view.state.selected_index <= length(view.state.options)
        view.state.options[view.state.selected_index]
    else
        placeholder_text
    end

    text_component = Text(
        display_text;
        style=view.style.text_style,
        horizontal_align=:left,
        vertical_align=:middle
    )

    # Position text with proper vertical centering
    text_x = x + view.style.padding
    text_y = y + view.style.padding
    available_text_width = width - 2 * view.style.padding - 20.0f0  # Reserve space for arrow
    text_height = height - 2 * view.style.padding

    interpret_view(text_component, text_x, text_y, available_text_width, text_height, projection_matrix)

    # Draw dropdown arrow
    draw_dropdown_arrow(view, x + width - view.style.padding - 10.0f0, y + height / 2.0f0, projection_matrix)
end

function draw_dropdown_list(view::DropdownView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Draw background for the entire dropdown list
    vertex_positions = generate_rectangle_vertices(x, y, width, height)
    draw_rounded_rectangle(
        vertex_positions,
        width,
        height,
        view.style.background_color,
        view.style.border_color,
        view.style.border_width,
        view.style.corner_radius,
        projection_matrix,
        1.5f0
    )

    # Draw each visible option
    visible_items = min(length(view.state.options), view.style.max_visible_items)

    for i in 1:visible_items
        if i > length(view.state.options)
            break
        end

        item_y = y + (i - 1) * view.style.item_height_px
        item_height = view.style.item_height_px

        # Highlight hovered item
        if view.state.hover_index == i
            highlight_vertices = generate_rectangle_vertices(x, item_y, width, item_height)
            draw_rounded_rectangle(
                highlight_vertices,
                width,
                item_height,
                view.style.background_color_hover,
                Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.0f0), # No border for highlight
                0.0f0,
                0.0f0,
                projection_matrix,
                1.5f0
            )
        end

        # Draw option text
        option_text = view.state.options[i]
        text_component = Text(
            option_text;
            style=view.style.text_style,
            horizontal_align=:left,
            vertical_align=:middle
        )

        # Position text with proper vertical centering
        text_x = x + view.style.padding
        text_y = item_y
        available_text_width = width - 2 * view.style.padding
        text_height = item_height

        interpret_view(text_component, text_x, text_y, available_text_width, text_height, projection_matrix)
    end
end

function draw_dropdown_arrow(view::DropdownView, x::Float32, y::Float32, projection_matrix::Mat4{Float32})
    # Simple arrow indicator using text
    arrow_text = view.state.is_open ? "▲" : "▼"

    arrow_component = Text(
        arrow_text;
        style=TextStyle(size_px=12, color=view.style.arrow_color),
        horizontal_align=:center,
        vertical_align=:middle
    )

    # Give the arrow a small area to center within
    arrow_size = 16.0f0  # Fixed size for arrow area
    arrow_x = x - arrow_size / 2.0f0
    arrow_y = y - arrow_size / 2.0f0

    interpret_view(arrow_component, arrow_x, arrow_y, arrow_size, arrow_size, projection_matrix)
end

function detect_click(view::DropdownView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    button_height = view.style.text_style.size_px + 2 * view.style.padding
    mouse_x, mouse_y = mouse_state.x, mouse_state.y

    # Check if mouse is over the dropdown button
    button_hovered = inside_component(view, x, y, width, button_height, mouse_x, mouse_y)

    # Update hover state for button
    if view.state.is_hovered != button_hovered
        new_state = DropdownState(view.state; is_hovered=button_hovered)
        view.on_state_change(new_state)
    end

    # Handle click events - use was_clicked for better click detection
    if mouse_state.was_clicked[LeftButton]
        if button_hovered
            # Toggle dropdown open/closed
            new_state = DropdownState(view.state; is_open=!view.state.is_open, hover_index=0)
            view.on_state_change(new_state)
            return
        elseif view.state.is_open
            # Check if click is on dropdown list
            dropdown_y = y + button_height
            visible_items = min(length(view.state.options), view.style.max_visible_items)
            dropdown_height = visible_items * view.style.item_height_px

            if (mouse_x >= x && mouse_x <= x + width &&
                mouse_y >= dropdown_y && mouse_y <= dropdown_y + dropdown_height)

                # Calculate which item was clicked
                relative_y = mouse_y - dropdown_y
                clicked_index = Int(floor(relative_y / view.style.item_height_px)) + 1

                if clicked_index >= 1 && clicked_index <= length(view.state.options)
                    # Select the item and close dropdown
                    new_state = DropdownState(view.state;
                        selected_index=clicked_index,
                        is_open=false,
                        hover_index=0)
                    view.on_state_change(new_state)
                    view.on_select(view.state.options[clicked_index], clicked_index)
                end
                return
            else
                # Click outside dropdown - close it
                new_state = DropdownState(view.state; is_open=false, hover_index=0)
                view.on_state_change(new_state)
            end
        end
    end

    # Handle hover for dropdown items
    if view.state.is_open
        dropdown_y = y + button_height
        visible_items = min(length(view.state.options), view.style.max_visible_items)
        dropdown_height = visible_items * view.style.item_height_px

        if (mouse_x >= x && mouse_x <= x + width &&
            mouse_y >= dropdown_y && mouse_y <= dropdown_y + dropdown_height)

            relative_y = mouse_y - dropdown_y
            hover_index = Int(floor(relative_y / view.style.item_height_px)) + 1

            if hover_index != view.state.hover_index && hover_index >= 1 && hover_index <= length(view.state.options)
                new_state = DropdownState(view.state; hover_index=hover_index)
                view.on_state_change(new_state)
            end
        else
            # Mouse not over dropdown items
            if view.state.hover_index != 0
                new_state = DropdownState(view.state; hover_index=0)
                view.on_state_change(new_state)
            end
        end
    end
end
