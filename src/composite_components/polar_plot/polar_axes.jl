"""
Draw polar coordinate axes (radial circles and angular lines).
"""

"""
Draw radial grid circles at specified radii.
"""
function draw_radial_circles(
    center_x::Float32,
    center_y::Float32,
    radii::Vector{Float32},
    color::Vec4f,
    width::Float32,
    projection_matrix::Mat4{Float32};
    anti_aliasing_width::Float32=1.0f0,
    num_segments::Int=100
)
    # Draw each circle using line segments
    for radius in radii
        # Generate circle points
        x_points = Float32[]
        y_points = Float32[]

        for i in 0:num_segments
            angle = 2.0f0 * Float32(π) * i / num_segments
            x = center_x + radius * cos(angle)
            y = center_y + radius * sin(angle)
            push!(x_points, x)
            push!(y_points, y)
        end

        # Use identity transform (already in screen coordinates)
        identity_transform(x, y) = (x, y)

        # Draw the circle
        draw_line_plot(
            x_points,
            y_points,
            identity_transform,
            color,
            width,
            SOLID,
            projection_matrix;
            anti_aliasing_width=anti_aliasing_width
        )
    end
end

"""
Draw angular grid lines (spokes) from center.
"""
function draw_angular_lines(
    center_x::Float32,
    center_y::Float32,
    max_radius::Float32,
    angles::Vector{Float32},
    theta_start::Float32,
    theta_direction::Symbol,
    color::Vec4f,
    width::Float32,
    projection_matrix::Mat4{Float32};
    anti_aliasing_width::Float32=1.0f0
)
    # Draw each spoke
    for angle in angles
        # Convert polar to Cartesian for the end point
        end_x, end_y = polar_to_cartesian(
            max_radius,
            angle,
            theta_start,
            theta_direction,
            center_x,
            center_y
        )

        # Line from center to edge
        x_points = Float32[center_x, end_x]
        y_points = Float32[center_y, end_y]

        # Use identity transform (already in screen coordinates)
        identity_transform(x, y) = (x, y)

        # Draw the spoke
        draw_line_plot(
            x_points,
            y_points,
            identity_transform,
            color,
            width,
            SOLID,
            projection_matrix;
            anti_aliasing_width=anti_aliasing_width
        )
    end
end

"""
Draw radial tick marks on the outer circle at angular positions.
"""
function draw_radial_ticks(
    center_x::Float32,
    center_y::Float32,
    max_radius::Float32,
    angles::Vector{Float32},
    theta_start::Float32,
    theta_direction::Symbol,
    tick_size::Float32,
    color::Vec4f,
    width::Float32,
    projection_matrix::Mat4{Float32};
    anti_aliasing_width::Float32=1.0f0
)
    # Draw tick mark at each angular position
    for angle in angles
        # Outer point (on the circle)
        outer_x, outer_y = polar_to_cartesian(
            max_radius,
            angle,
            theta_start,
            theta_direction,
            center_x,
            center_y
        )

        # Inner point (tick extends inward)
        inner_x, inner_y = polar_to_cartesian(
            max_radius - tick_size,
            angle,
            theta_start,
            theta_direction,
            center_x,
            center_y
        )

        # Draw tick mark
        x_points = Float32[inner_x, outer_x]
        y_points = Float32[inner_y, outer_y]

        identity_transform(x, y) = (x, y)

        draw_line_plot(
            x_points,
            y_points,
            identity_transform,
            color,
            width,
            SOLID,
            projection_matrix;
            anti_aliasing_width=anti_aliasing_width
        )
    end
end

"""
Draw angular tick marks on radial circles.
"""
function draw_angular_ticks(
    center_x::Float32,
    center_y::Float32,
    radii::Vector{Float32},
    theta_start::Float32,
    theta_direction::Symbol,
    tick_size::Float32,
    color::Vec4f,
    width::Float32,
    projection_matrix::Mat4{Float32};
    anti_aliasing_width::Float32=1.0f0
)
    # Draw tick marks on each radial circle
    for radius in radii
        # Skip the center
        if radius < 1e-6
            continue
        end

        # Calculate perpendicular direction for tick
        # Tick points radially from theta_start direction
        tick_angle = theta_start

        # Outer point (on the circle)
        outer_x, outer_y = polar_to_cartesian(
            radius,
            tick_angle,
            theta_start,
            theta_direction,
            center_x,
            center_y
        )

        # Inner point (tick extends inward)
        inner_x, inner_y = polar_to_cartesian(
            radius - tick_size,
            tick_angle,
            theta_start,
            theta_direction,
            center_x,
            center_y
        )

        # Draw tick mark
        x_points = Float32[inner_x, outer_x]
        y_points = Float32[inner_y, outer_y]

        identity_transform(x, y) = (x, y)

        draw_line_plot(
            x_points,
            y_points,
            identity_transform,
            color,
            width,
            SOLID,
            projection_matrix;
            anti_aliasing_width=anti_aliasing_width
        )
    end
end

"""
Draw radial labels at specified radii.
"""
function draw_radial_labels(
    center_x::Float32,
    center_y::Float32,
    radii::Vector{Float32},
    r_min::Float32,
    r_max::Float32,
    theta_start::Float32,
    label_color::Vec4f,
    label_size_px::Int,
    projection_matrix::Mat4{Float32}
)
    text_style = TextStyle(size_px=label_size_px, color=label_color)

    # Place labels at theta_start + π/2 (perpendicular to starting direction)
    label_angle = theta_start + Float32(π) / 2.0f0

    for (i, radius) in enumerate(radii)
        # Skip the center point
        if radius < 1e-6
            continue
        end

        # Calculate actual r value for this radius
        r_value = r_min + (radius / radii[end]) * (r_max - r_min)

        # Format label
        if r_value >= 100 || r_value <= -100
            label_text = string(round(Int, r_value))
        elseif abs(r_value) < 0.01
            label_text = "0"
        else
            label_text = string(round(r_value, digits=2))
        end

        # Position label slightly outside the circle
        label_x = center_x + (radius + 5.0f0) * cos(label_angle)
        label_y = center_y + (radius + 5.0f0) * sin(label_angle)

        # Draw label
        font = get_font(text_style)
        draw_text(font, label_text, label_x, label_y, label_size_px, projection_matrix, label_color)
    end
end

"""
Draw angular labels at specified angles.
"""
function draw_angular_labels(
    center_x::Float32,
    center_y::Float32,
    max_radius::Float32,
    angles::Vector{Float32},
    theta_start::Float32,
    theta_direction::Symbol,
    label_format::Symbol,
    label_color::Vec4f,
    label_size_px::Int,
    projection_matrix::Mat4{Float32}
)
    text_style = TextStyle(size_px=label_size_px, color=label_color)
    label_offset = 15.0f0  # Pixels beyond max radius

    for angle in angles
        # Format label based on format preference
        if label_format == :degrees
            degrees = rad2deg(angle)
            label_text = string(round(Int, degrees)) * "°"
        else
            pi_mult = angle / Float32(π)
            if abs(pi_mult) < 0.01
                label_text = "0"
            else
                label_text = string(round(pi_mult, digits=2)) * "π"
            end
        end

        # Position label beyond max radius
        label_x, label_y = polar_to_cartesian(
            max_radius + label_offset,
            angle,
            theta_start,
            theta_direction,
            center_x,
            center_y
        )

        # Center text at label position
        font = get_font(text_style)
        text_width = measure_word_width(font, label_text, text_style.size_px)
        label_x -= text_width / 2.0f0

        # Draw label
        draw_text(font, label_text, label_x, label_y, label_size_px, projection_matrix, label_color)
    end
end
