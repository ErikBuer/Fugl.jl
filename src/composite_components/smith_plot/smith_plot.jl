"""
Smith chart component for plotting reflection coefficient data.

The chart uses normalized impedance z = r + jx and maps it to reflection
coefficient Gamma via:
Gamma = (z - 1) / (z + 1)
"""

include("smith_style.jl")
include("smith_state.jl")

struct SmithTrace
    gamma_re::Vector{Float32}
    gamma_im::Vector{Float32}
    label::String
    color::Vec4f
    width::Float32
    show_markers::Bool
    marker_size::Float32
    muted::Bool
    hovered::Bool
end

function SmithTrace(
    gamma_re::Vector{<:Real},
    gamma_im::Vector{<:Real};
    label::String="",
    color::Vec4f=Vec4f(0.05f0, 0.45f0, 0.85f0, 1.0f0),
    width::Float32=2.2f0,
    show_markers::Bool=false,
    marker_size::Float32=4.5f0,
    muted::Bool=false,
    hovered::Bool=false
)::SmithTrace
    return SmithTrace(
        Float32.(gamma_re),
        Float32.(gamma_im),
        label,
        color,
        width,
        show_markers,
        marker_size,
        muted,
        hovered
    )
end

function SmithTrace(trace::SmithTrace;
    gamma_re=trace.gamma_re,
    gamma_im=trace.gamma_im,
    label=trace.label,
    color=trace.color,
    width=trace.width,
    show_markers=trace.show_markers,
    marker_size=trace.marker_size,
    muted=trace.muted,
    hovered=trace.hovered
)::SmithTrace
    return SmithTrace(gamma_re, gamma_im, label, color, width, show_markers, marker_size, muted, hovered)
end

"""
Create a Smith trace from normalized impedance points z = r + jx.
"""
function SmithTraceFromNormalizedImpedance(
    r_data::Vector{<:Real},
    x_data::Vector{<:Real};
    label::String="",
    color::Vec4f=Vec4f(0.05f0, 0.45f0, 0.85f0, 1.0f0),
    width::Float32=2.2f0,
    show_markers::Bool=false,
    marker_size::Float32=4.5f0,
    muted::Bool=false
)::SmithTrace
    n = min(length(r_data), length(x_data))
    gamma_re = Vector{Float32}(undef, n)
    gamma_im = Vector{Float32}(undef, n)

    for i in 1:n
        r = Float32(r_data[i])
        x = Float32(x_data[i])

        den_re = r + 1.0f0
        den_im = x
        den_mag2 = den_re * den_re + den_im * den_im

        if den_mag2 < 1f-12
            gamma_re[i] = NaN32
            gamma_im[i] = NaN32
            continue
        end

        num_re = r - 1.0f0
        num_im = x

        gamma_re[i] = (num_re * den_re + num_im * den_im) / den_mag2
        gamma_im[i] = (num_im * den_re - num_re * den_im) / den_mag2
    end

    return SmithTrace(gamma_re, gamma_im;
        label=label,
        color=color,
        width=width,
        show_markers=show_markers,
        marker_size=marker_size,
        muted=muted
    )
end

"""
Create a Smith trace from unnormalized impedance Z = R + jX using z0.
"""
function SmithTraceFromImpedance(
    r_data::Vector{<:Real},
    x_data::Vector{<:Real};
    z0::Real=50.0,
    label::String="",
    color::Vec4f=Vec4f(0.05f0, 0.45f0, 0.85f0, 1.0f0),
    width::Float32=2.2f0,
    show_markers::Bool=false,
    marker_size::Float32=4.5f0,
    muted::Bool=false
)::SmithTrace
    z0_f = Float32(z0)
    return SmithTraceFromNormalizedImpedance(
        Float32.(r_data) ./ z0_f,
        Float32.(x_data) ./ z0_f;
        label=label,
        color=color,
        width=width,
        show_markers=show_markers,
        marker_size=marker_size,
        muted=muted
    )
end

"""
Create a Smith trace from normalized admittance y = g + jb.
Converts y -> z = 1/y, then z -> Gamma.
"""
function SmithTraceFromNormalizedAdmittance(
    g_data::Vector{<:Real},
    b_data::Vector{<:Real};
    label::String="",
    color::Vec4f=Vec4f(0.85f0, 0.30f0, 0.10f0, 1.0f0),
    width::Float32=2.2f0,
    show_markers::Bool=false,
    marker_size::Float32=4.5f0,
    muted::Bool=false
)::SmithTrace
    n = min(length(g_data), length(b_data))
    r_data = Vector{Float32}(undef, n)
    x_data = Vector{Float32}(undef, n)

    for i in 1:n
        g = Float32(g_data[i])
        b = Float32(b_data[i])
        den = g * g + b * b
        if den < 1f-12
            r_data[i] = Inf32
            x_data[i] = 0.0f0
        else
            r_data[i] = g / den
            x_data[i] = -b / den
        end
    end

    return SmithTraceFromNormalizedImpedance(r_data, x_data;
        label=label,
        color=color,
        width=width,
        show_markers=show_markers,
        marker_size=marker_size,
        muted=muted
    )
end

struct SmithPlotView <: AbstractView
    traces::Vector{SmithTrace}
    style::SmithStyle
    state::SmithState
    on_state_change::Function
end

function SmithPlot(
    traces::Vector{SmithTrace},
    style::SmithStyle=SmithStyle(),
    state::SmithState=SmithState(),
    on_state_change::Function=(new_state) -> nothing
)::SmithPlotView
    return SmithPlotView(traces, style, state, on_state_change)
end

function measure(view::SmithPlotView)::Tuple{Float32,Float32}
    return (Inf32, Inf32)
end

function apply_layout(view::SmithPlotView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function _smith_data_to_screen(
    gamma_re::Float32,
    gamma_im::Float32,
    center_x::Float32,
    center_y::Float32,
    radius::Float32
)::Tuple{Float32,Float32}
    return (center_x + gamma_re * radius, center_y - gamma_im * radius)
end

function _draw_circle(
    center_x::Float32,
    center_y::Float32,
    radius::Float32,
    color::Vec4f,
    width::Float32,
    projection_matrix::Mat4{Float32},
    anti_aliasing_width::Float32;
    start_angle::Float32=0.0f0,
    end_angle::Float32=2.0f0 * Float32(pi),
    segments::Int=180
)
    if radius <= 0
        return
    end

    x_points = Float32[]
    y_points = Float32[]
    span = end_angle - start_angle
    nseg = max(8, Int(round(segments * abs(span) / (2.0f0 * Float32(pi)))))

    for i in 0:nseg
        t = start_angle + span * (Float32(i) / Float32(nseg))
        push!(x_points, center_x + radius * cos(t))
        push!(y_points, center_y + radius * sin(t))
    end

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

function _draw_horizontal_line(
    y::Float32,
    x_min::Float32,
    x_max::Float32,
    color::Vec4f,
    width::Float32,
    projection_matrix::Mat4{Float32},
    anti_aliasing_width::Float32
)
    identity_transform(x, yy) = (x, yy)
    draw_line_plot(
        Float32[x_min, x_max],
        Float32[y, y],
        identity_transform,
        color,
        width,
        SOLID,
        projection_matrix;
        anti_aliasing_width=anti_aliasing_width
    )
end

function _draw_vertical_line(
    x::Float32,
    y_min::Float32,
    y_max::Float32,
    color::Vec4f,
    width::Float32,
    projection_matrix::Mat4{Float32},
    anti_aliasing_width::Float32
)
    identity_transform(xx, y) = (xx, y)
    draw_line_plot(
        Float32[x, x],
        Float32[y_min, y_max],
        identity_transform,
        color,
        width,
        SOLID,
        projection_matrix;
        anti_aliasing_width=anti_aliasing_width
    )
end

function _draw_smith_circle_arc(
    c_re::Float32,
    c_im::Float32,
    circ_radius::Float32,
    center_x::Float32,
    center_y::Float32,
    chart_radius::Float32,
    color::Vec4f,
    width::Float32,
    projection_matrix::Mat4{Float32},
    anti_aliasing_width::Float32;
    n_segments::Int=480
)
    x_points = Float32[]
    y_points = Float32[]
    sizehint!(x_points, n_segments + 2)
    sizehint!(y_points, n_segments + 2)

    clip_r2 = 0.9985f0 * 0.9985f0
    two_pi = 2.0f0 * Float32(pi)

    for i in 0:n_segments
        t = two_pi * Float32(i) / Float32(n_segments)
        re = c_re + circ_radius * cos(t)
        im = c_im + circ_radius * sin(t)

        mag2 = re * re + im * im
        if mag2 > 1.0001f0
            push!(x_points, NaN32)
            push!(y_points, NaN32)
            continue
        end

        # Pull back from boundary so AA fringe stays inside Smith circle.
        if mag2 > clip_r2
            scale = 0.9985f0 / sqrt(mag2)
            re *= scale
            im *= scale
        end

        push!(x_points, center_x + re * chart_radius)
        push!(y_points, center_y - im * chart_radius)
    end

    identity_transform(x, y) = (x, y)
    draw_line_plot(
        x_points, y_points, identity_transform,
        color, width, SOLID, projection_matrix;
        anti_aliasing_width=anti_aliasing_width
    )
end

function _draw_constant_r_curve(
    r::Float32,
    center_x::Float32,
    center_y::Float32,
    chart_radius::Float32,
    color::Vec4f,
    width::Float32,
    projection_matrix::Mat4{Float32},
    anti_aliasing_width::Float32
)
    # Constant-resistance circle: center=(r/(r+1), 0), radius=1/(r+1) in Gamma plane.
    c_re = r / (1.0f0 + r)
    circ_r = 1.0f0 / (1.0f0 + r)
    _draw_smith_circle_arc(c_re, 0.0f0, circ_r, center_x, center_y, chart_radius, color, width, projection_matrix, anti_aliasing_width)
end

function _draw_constant_x_curve(
    x::Float32,
    center_x::Float32,
    center_y::Float32,
    chart_radius::Float32,
    color::Vec4f,
    width::Float32,
    projection_matrix::Mat4{Float32},
    anti_aliasing_width::Float32
)
    if abs(x) < 1f-6
        return
    end
    # Constant-reactance circle: center=(1, 1/x), radius=1/|x| in Gamma plane.
    c_im = 1.0f0 / x
    circ_r = abs(1.0f0 / x)
    _draw_smith_circle_arc(1.0f0, c_im, circ_r, center_x, center_y, chart_radius, color, width, projection_matrix, anti_aliasing_width)
end

function _draw_constant_g_curve(
    g::Float32,
    center_x::Float32,
    center_y::Float32,
    chart_radius::Float32,
    color::Vec4f,
    width::Float32,
    projection_matrix::Mat4{Float32},
    anti_aliasing_width::Float32
)
    # Constant-conductance circle: center=(-g/(g+1), 0), radius=1/(g+1) in Gamma plane.
    c_re = -g / (1.0f0 + g)
    circ_r = 1.0f0 / (1.0f0 + g)
    _draw_smith_circle_arc(c_re, 0.0f0, circ_r, center_x, center_y, chart_radius, color, width, projection_matrix, anti_aliasing_width)
end

function _draw_constant_b_curve(
    b::Float32,
    center_x::Float32,
    center_y::Float32,
    chart_radius::Float32,
    color::Vec4f,
    width::Float32,
    projection_matrix::Mat4{Float32},
    anti_aliasing_width::Float32
)
    if abs(b) < 1f-6
        return
    end
    # Constant-susceptance circle: center=(-1, -1/b), radius=1/|b| in Gamma plane.
    c_im = -1.0f0 / b
    circ_r = abs(1.0f0 / b)
    _draw_smith_circle_arc(-1.0f0, c_im, circ_r, center_x, center_y, chart_radius, color, width, projection_matrix, anti_aliasing_width)
end

# Circles only — real axis is drawn separately after, so it sits above them.
function _draw_smith_grid(
    style::SmithStyle,
    center_x::Float32,
    center_y::Float32,
    chart_radius::Float32,
    projection_matrix::Mat4{Float32}
)
    aa = style.anti_aliasing_width

    r_vals = Float32[0.0f0, 0.2f0, 0.5f0, 1.0f0, 2.0f0, 5.0f0]
    x_vals = Float32[0.2f0, 0.5f0, 1.0f0, 2.0f0, 5.0f0]

    if style.show_admittance_grid
        adm_color = Vec4f(style.grid_color[1], style.grid_color[2], style.grid_color[3], 0.45f0)
        for g in r_vals
            _draw_constant_g_curve(g, center_x, center_y, chart_radius, adm_color, style.grid_width, projection_matrix, aa)
        end
        for b in x_vals
            _draw_constant_b_curve(b, center_x, center_y, chart_radius, adm_color, style.grid_width, projection_matrix, aa)
            _draw_constant_b_curve(-b, center_x, center_y, chart_radius, adm_color, style.grid_width, projection_matrix, aa)
        end
    end

    for r in r_vals
        _draw_constant_r_curve(r, center_x, center_y, chart_radius, style.grid_color, style.grid_width, projection_matrix, aa)
    end

    for x in x_vals
        _draw_constant_x_curve(x, center_x, center_y, chart_radius, style.grid_color, style.grid_width, projection_matrix, aa)
        _draw_constant_x_curve(-x, center_x, center_y, chart_radius, style.grid_color, style.grid_width, projection_matrix, aa)
    end
end

# The real axis (horizontal) is drawn after all circles so it is on top of them.
function _draw_smith_real_axis(
    style::SmithStyle,
    center_x::Float32,
    center_y::Float32,
    chart_radius::Float32,
    projection_matrix::Mat4{Float32}
)
    _draw_horizontal_line(
        center_y,
        center_x - chart_radius,
        center_x + chart_radius,
        style.axis_color,
        style.axis_width,
        projection_matrix,
        style.anti_aliasing_width
    )
end

function _draw_smith_outer_circle(
    style::SmithStyle,
    center_x::Float32,
    center_y::Float32,
    chart_radius::Float32,
    projection_matrix::Mat4{Float32}
)
    _draw_circle(
        center_x,
        center_y,
        chart_radius,
        style.outer_circle_color,
        style.outer_circle_width,
        projection_matrix,
        style.anti_aliasing_width
    )
end

function _draw_smith_labels(
    style::SmithStyle,
    center_x::Float32,
    center_y::Float32,
    chart_radius::Float32,
    projection_matrix::Mat4{Float32}
)
    if !style.show_labels
        return
    end

    text_style = TextStyle(size_points=style.label_size_points, color=style.label_color)
    font = get_font(text_style)

    labels = [
        ("0", -0.98f0, 0.03f0),
        ("0.2", -0.52f0, 0.03f0),
        ("0.5", -0.18f0, 0.03f0),
        ("1", 0.02f0, 0.03f0),
        ("2", 0.34f0, 0.03f0),
        ("5", 0.67f0, 0.03f0),
        ("inf", 0.92f0, 0.03f0)
    ]

    for (txt, gx, gy) in labels
        tx = center_x + gx * chart_radius
        ty = center_y - gy * chart_radius
        draw_text(font, txt, tx, ty, text_style.size_points, projection_matrix, style.label_color)
    end

    draw_text(font, "+j", center_x + 0.03f0 * chart_radius, center_y - 0.76f0 * chart_radius, text_style.size_points, projection_matrix, style.label_color)
    draw_text(font, "-j", center_x + 0.03f0 * chart_radius, center_y + 0.81f0 * chart_radius, text_style.size_points, projection_matrix, style.label_color)
end

function _draw_trace(
    trace::SmithTrace,
    style::SmithStyle,
    center_x::Float32,
    center_y::Float32,
    chart_radius::Float32,
    projection_matrix::Mat4{Float32}
)
    if trace.muted
        return
    end

    n = min(length(trace.gamma_re), length(trace.gamma_im))
    if n < 1
        return
    end

    x_points = Float32[]
    y_points = Float32[]
    identity_transform(x, y) = (x, y)

    # Clipping as grid curves to avoid tiny overdraw outside boundary.
    clip_radius2 = 0.9985f0 * 0.9985f0

    for i in 1:n
        re = trace.gamma_re[i]
        im = trace.gamma_im[i]
        if isnan(re) || isnan(im)
            push!(x_points, NaN32)
            push!(y_points, NaN32)
            continue
        end

        # Culling
        mag2 = re * re + im * im
        if mag2 > 1.0f0
            push!(x_points, NaN32)
            push!(y_points, NaN32)
            continue
        end

        if mag2 > clip_radius2
            scale = 0.9985f0 / sqrt(mag2)
            re *= scale
            im *= scale
        end

        sx, sy = _smith_data_to_screen(re, im, center_x, center_y, chart_radius)
        push!(x_points, sx)
        push!(y_points, sy)
    end

    if length(x_points) >= 2
        draw_line_plot(
            x_points,
            y_points,
            identity_transform,
            trace.color,
            trace.width,
            SOLID,
            projection_matrix;
            anti_aliasing_width=style.anti_aliasing_width
        )
    end

    if style.show_markers && trace.show_markers
        marker_x = Float32[]
        marker_y = Float32[]
        for i in 1:n
            re = trace.gamma_re[i]
            im = trace.gamma_im[i]
            if isnan(re) || isnan(im)
                continue
            end
            if re * re + im * im > 1.0001f0
                continue
            end
            sx, sy = _smith_data_to_screen(re, im, center_x, center_y, chart_radius)
            push!(marker_x, sx)
            push!(marker_y, sy)
        end

        if !isempty(marker_x)
            draw_scatter_plot(
                marker_x,
                marker_y,
                identity_transform,
                style.marker_fill_color,
                style.marker_border_color,
                trace.marker_size,
                style.marker_border_width,
                CIRCLE,
                projection_matrix;
                anti_aliasing_width=style.anti_aliasing_width
            )
        end
    end
end

function interpret_view(
    view::SmithPlotView,
    x_points::Float32,
    y_points::Float32,
    width_points::Float32,
    height_points::Float32,
    projection_matrix::Mat4{Float32},
    cursor_position::Point2f,
    window_size::Size
)
    # Use same render-cache approach as Plot/PolarPlot for performance.
    dpi_scaling = get_current_dpi_scaling()
    scale_factor = dpi_scaling[].manual_scale * get_system_dpi_ratio(dpi_scaling)

    cache_width_pixels = Int32(round(width_points * scale_factor))
    cache_height_pixels = Int32(round(height_points * scale_factor))

    if cache_width_pixels <= 0 || cache_height_pixels <= 0
        return
    end

    cache = get_render_cache(view.state.cache_id)
    content_hash = hash((view.traces, view.style, view.state))
    bounds_pixels = (
        Float32(x_points) * scale_factor,
        Float32(y_points) * scale_factor,
        Float32(width_points) * scale_factor,
        Float32(height_points) * scale_factor
    )

    needs_redraw = should_invalidate_cache(cache, content_hash, bounds_pixels)

    if needs_redraw || !cache.is_valid
        if cache.framebuffer === nothing || cache.cache_width != cache_width_pixels || cache.cache_height != cache_height_pixels
            framebuffer, color_texture, depth_texture = create_render_framebuffer(cache_width_pixels, cache_height_pixels; with_depth=false)
            update_cache!(cache, framebuffer, color_texture, depth_texture, content_hash, bounds_pixels)
        else
            update_cache!(cache, cache.framebuffer, cache.color_texture, cache.depth_texture, content_hash, bounds_pixels)
        end

        push_framebuffer!(cache.framebuffer)
        push_viewport!(Int32(0), Int32(0), cache.cache_width, cache.cache_height)

        try
            s = view.style
            ModernGL.glClearColor(s.background_color[1], s.background_color[2], s.background_color[3], s.background_color[4])
            ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT | ModernGL.GL_DEPTH_BUFFER_BIT)

            fb_projection = get_orthographic_matrix(0.0f0, width_points, height_points, 0.0f0, -1.0f0, 1.0f0)

            inner_w = width_points - 2.0f0 * s.padding
            inner_h = height_points - 2.0f0 * s.padding
            if inner_w > 0 && inner_h > 0
                chart_radius = min(inner_w, inner_h) / 2.0f0
                center_x = s.padding + inner_w / 2.0f0
                center_y = s.padding + inner_h / 2.0f0

                # Render order: admittance circles → impedance circles → real axis
                # → labels → data traces → outer boundary (topmost)
                _draw_smith_grid(s, center_x, center_y, chart_radius, fb_projection)
                _draw_smith_real_axis(s, center_x, center_y, chart_radius, fb_projection)
                _draw_smith_labels(s, center_x, center_y, chart_radius, fb_projection)

                for tr in view.traces
                    _draw_trace(tr, s, center_x, center_y, chart_radius, fb_projection)
                end

                _draw_smith_outer_circle(s, center_x, center_y, chart_radius, fb_projection)
            end
        finally
            pop_viewport!()
            pop_framebuffer!()
        end
    end

    if cache.is_valid && cache.color_texture !== nothing
        draw_cached_texture(cache.color_texture, x_points, y_points, width_points, height_points, projection_matrix)
    end
end
