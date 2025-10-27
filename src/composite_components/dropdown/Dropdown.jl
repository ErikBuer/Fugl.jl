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
