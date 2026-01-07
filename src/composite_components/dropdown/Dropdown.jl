include("dropdown_style.jl")
include("dropdown_state.jl")

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

include("draw.jl")

function measure(view::DropdownView)::Tuple{Float32,Float32}
    # Always return just the button height - dropdown list overlays outside bounds
    button_height = view.style.text_style.size_px + 2 * view.style.padding
    return (Inf32, button_height)
end

"""
Measure the width of the component when constrained by available height.
"""
function measure_width(view::DropdownView, available_height::Float32)::Float32
    # Base the width on the contents of the current selection.
    padding = 2 * view.style.padding + 20.0f0  # Extra space for arrow (arrow size is ~16px + padding)

    # Get the text to measure
    selected_text = if view.state.selected_index > 0 && view.state.selected_index <= length(view.state.options)
        view.state.options[view.state.selected_index]
    else
        view.placeholder_text
    end

    # Measure the width of the selected text using the same method as Text component
    font = view.style.text_style.font
    size_px = view.style.text_style.size_px
    text_width = measure_word_width_cached(font, selected_text, size_px)

    return text_width + padding
end

function preferred_height(view::DropdownView)::Bool
    return true
end

"""
Measure the height of the component when constrained by available width.
"""
function measure_height(view::DropdownView, available_width::Float32)::Float32
    # The dropdown height is just the button height - the dropdown list overlays outside bounds
    button_height = view.style.text_style.size_px + 2 * view.style.padding
    return button_height
end

function interpret_view(view::DropdownView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Calculate button height
    button_height = view.style.text_style.size_px + 2 * view.style.padding

    # Draw the main dropdown button
    draw_dropdown_button(view, x, y, width, button_height, projection_matrix, mouse_x, mouse_y)

    # If open, add dropdown list to overlay system, ensuring it draws on top of other UI.
    if view.state.is_open
        dropdown_y = y + button_height
        filtered_options = get_filtered_options(view.state)
        visible_items = min(length(filtered_options), view.style.max_visible_items)
        dropdown_height = visible_items * view.style.item_height_px

        # Add overlay function to render dropdown list on top
        add_overlay_function(() -> draw_dropdown_list(view, x, dropdown_y, width, dropdown_height, projection_matrix))
    end
end

function detect_click(view::DropdownView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    button_height = view.style.text_style.size_px + 2 * view.style.padding
    mouse_x, mouse_y = mouse_state.x, mouse_state.y

    # Handle key input when dropdown is open (search functionality)
    if view.state.is_open
        handle_search_input(view, mouse_state)
    end

    # Check if mouse is over the dropdown button
    button_hovered = inside_component(view, x, y, width, button_height, mouse_x, mouse_y)

    # Update hover state for button
    if view.state.is_hovered != button_hovered
        new_state = DropdownState(view.state; is_hovered=button_hovered)
        view.on_state_change(new_state)
    end

    # Handle scroll wheel events when dropdown is open
    if view.state.is_open && (mouse_state.scroll_y != 0.0)
        dropdown_y = y + button_height
        visible_items = min(length(view.state.options), view.style.max_visible_items)
        dropdown_height = visible_items * view.style.item_height_px

        # Check if mouse is over dropdown area
        mouse_over_dropdown = (mouse_x >= x && mouse_x <= x + width &&
                               mouse_y >= dropdown_y && mouse_y <= dropdown_y + dropdown_height)

        if mouse_over_dropdown
            # Calculate new scroll offset (discrete scrolling) based on filtered options
            filtered_options = get_filtered_options(view.state)
            max_scroll = max(0, length(filtered_options) - view.style.max_visible_items)
            new_scroll_offset = if mouse_state.scroll_y > 0.0
                # Scroll up (show earlier items)
                max(0, view.state.scroll_offset - 1)
            else
                # Scroll down (show later items)
                min(max_scroll, view.state.scroll_offset + 1)
            end

            if new_scroll_offset != view.state.scroll_offset
                new_state = DropdownState(view.state; scroll_offset=new_scroll_offset, hover_index=0)
                view.on_state_change(new_state)
            end
            return
        end
    end

    # Handle click events - use was_clicked for better click detection
    if mouse_state.was_clicked[LeftButton]
        if button_hovered
            # Toggle dropdown open/closed, clear search when opening
            new_state = DropdownState(view.state; is_open=!view.state.is_open, hover_index=0, scroll_offset=0, search_text="")
            view.on_state_change(new_state)
            return
        elseif view.state.is_open
            # Check if click is on dropdown list
            dropdown_y = y + button_height
            filtered_options = get_filtered_options(view.state)
            visible_items = min(length(filtered_options), view.style.max_visible_items)
            dropdown_height = visible_items * view.style.item_height_px

            if (mouse_x >= x && mouse_x <= x + width &&
                mouse_y >= dropdown_y && mouse_y <= dropdown_y + dropdown_height)

                # Calculate which item was clicked (accounting for scroll offset and filtering)
                relative_y = mouse_y - dropdown_y
                visible_item_index = Int(floor(relative_y / view.style.item_height_px)) + 1
                filtered_item_index = visible_item_index + view.state.scroll_offset
                filtered_options = get_filtered_options(view.state)

                if filtered_item_index >= 1 && filtered_item_index <= length(filtered_options)
                    # Get the actual option index from the filtered index
                    actual_item_index = get_actual_option_index(view.state, filtered_item_index)
                    # Select the item and close dropdown
                    new_state = DropdownState(view.state;
                        selected_index=actual_item_index,
                        is_open=false,
                        hover_index=0,
                        scroll_offset=0,
                        search_text="")
                    view.on_state_change(new_state)
                    view.on_select(view.state.options[actual_item_index], actual_item_index)
                end
                return
            else
                # Click outside dropdown - close it
                new_state = DropdownState(view.state; is_open=false, hover_index=0, scroll_offset=0, search_text="")
                view.on_state_change(new_state)
            end
        end
    end

    # Handle hover for dropdown items (accounting for scroll offset)
    if view.state.is_open
        dropdown_y = y + button_height
        filtered_options = get_filtered_options(view.state)
        visible_items = min(length(filtered_options), view.style.max_visible_items)
        dropdown_height = visible_items * view.style.item_height_px

        if (mouse_x >= x && mouse_x <= x + width &&
            mouse_y >= dropdown_y && mouse_y <= dropdown_y + dropdown_height)

            relative_y = mouse_y - dropdown_y
            visible_item_index = Int(floor(relative_y / view.style.item_height_px)) + 1
            filtered_item_index = visible_item_index + view.state.scroll_offset
            filtered_options = get_filtered_options(view.state)
            actual_hover_index = get_actual_option_index(view.state, filtered_item_index)

            if actual_hover_index != view.state.hover_index && actual_hover_index >= 1 && actual_hover_index <= length(view.state.options) && filtered_item_index <= length(filtered_options)
                new_state = DropdownState(view.state; hover_index=actual_hover_index)
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

"""
Handle key input for dropdown search functionality.
"""
function handle_search_input(view::DropdownView, mouse_state::InputState)
    if !view.state.is_open
        return  # Only handle key input when dropdown is open
    end

    current_state = view.state
    search_changed = false

    # Handle backspace key to remove characters from search text
    for key_event in mouse_state.key_events
        if Int(key_event.action) == Int(GLFW.PRESS) || Int(key_event.action) == Int(GLFW.REPEAT)
            if key_event.key == GLFW.KEY_BACKSPACE && !isempty(current_state.search_text)
                # Remove last character from search text
                new_search_text = current_state.search_text[1:end-1]
                current_state = DropdownState(current_state;
                    search_text=new_search_text,
                    hover_index=0,
                    scroll_offset=0)
                search_changed = true
            elseif key_event.key == GLFW.KEY_ESCAPE
                # Clear search and close dropdown on Escape
                current_state = DropdownState(current_state;
                    is_open=false,
                    search_text="",
                    hover_index=0,
                    scroll_offset=0)
                search_changed = true
            end
        end
    end

    # Handle regular character input to add to search text
    for key in mouse_state.key_buffer
        if key == '\b'  # Handle backspace character
            if !isempty(current_state.search_text)
                # Remove last character from search text
                new_search_text = current_state.search_text[1:end-1]
                current_state = DropdownState(current_state;
                    search_text=new_search_text,
                    hover_index=0,
                    scroll_offset=0)
                search_changed = true
            end
        elseif isprint(key)  # Handle printable characters
            new_search_text = current_state.search_text * string(key)
            current_state = DropdownState(current_state;
                search_text=new_search_text,
                hover_index=0,
                scroll_offset=0)
            search_changed = true
        end
    end

    # Update state if search text changed
    if search_changed
        view.on_state_change(current_state)
    end
end
