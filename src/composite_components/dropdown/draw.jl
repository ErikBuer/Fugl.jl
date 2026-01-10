function draw_dropdown_button(view::DropdownView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
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
        view.placeholder_text
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

    interpret_view(text_component, text_x, text_y, available_text_width, text_height, projection_matrix, mouse_x, mouse_y)

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

    # Get filtered options based on search text
    filtered_options = get_filtered_options(view.state)

    # Draw each visible option (accounting for scroll offset and filtering)
    visible_items = min(length(filtered_options) - view.state.scroll_offset, view.style.max_visible_items)

    for i in 1:visible_items
        filtered_option_index = i + view.state.scroll_offset
        if filtered_option_index > length(filtered_options)
            break
        end

        # Get the actual option index for this filtered item
        actual_option_index = get_actual_option_index(view.state, filtered_option_index)
        if actual_option_index == 0
            continue  # Skip invalid indices
        end

        item_y = y + (i - 1) * view.style.item_height_px
        item_height = view.style.item_height_px

        # Highlight hovered item (compare with actual option index)
        if view.state.hover_index == actual_option_index
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

        # Draw option text (use actual option index)
        option_text = view.state.options[actual_option_index]
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

        interpret_view(text_component, text_x, text_y, available_text_width, text_height, projection_matrix, 0.0f0, 0.0f0)
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

    interpret_view(arrow_component, arrow_x, arrow_y, arrow_size, arrow_size, projection_matrix, 0.0f0, 0.0f0)
end