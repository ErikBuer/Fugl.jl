"""
Draw the popover panel background with shadow and border.
"""
function draw_popover_background(style::PopoverStyle, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    if style.shadow_offset > 0.0f0
        shadow_x = x + style.shadow_offset
        shadow_y = y + style.shadow_offset
        shadow_vertices = generate_rectangle_vertices(shadow_x, shadow_y, width, height)
        draw_rounded_rectangle(
            shadow_vertices,
            width,
            height,
            style.shadow_color,
            style.shadow_color,  # Shadow has no border
            0.0f0,
            style.corner_radius,
            projection_matrix,
            style.anti_aliasing_width
        )
    end

    vertex_positions = generate_rectangle_vertices(x, y, width, height)
    draw_rounded_rectangle(
        vertex_positions,
        width,
        height,
        style.background_color,
        style.border_color,
        style.border_width,
        style.corner_radius,
        projection_matrix,
        style.anti_aliasing_width
    )
end
