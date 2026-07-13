"""
Helper function to extract data bounds from any plot element
"""
function get_element_bounds(element::AbstractPlotElement)::Tuple{Float32,Float32,Float32,Float32}
    if element isa LinePlotElement || element isa ScatterPlotElement || element isa StemPlotElement
        if !isempty(element.x_data) && !isempty(element.y_data)
            min_x, max_x = extrema(element.x_data)
            min_y, max_y = extrema(element.y_data)
            return (min_x, max_x, min_y, max_y)
        end
    elseif element isa HeatmapElement
        min_x, max_x = element.x_range
        min_y, max_y = element.y_range
        return (min_x, max_x, min_y, max_y)
    elseif element isa VerticalColorbar
        # For vertical colorbar: thin width (0-1), height matches value range
        min_val, max_val = element.value_range
        return (0.0f0, 1.0f0, min_val, max_val)
    elseif element isa HorizontalColorbar
        # For horizontal colorbar: width matches value range, thin height (0-1)
        min_val, max_val = element.value_range
        return (min_val, max_val, 0.0f0, 1.0f0)
    end
    return (0.0f0, 1.0f0, 0.0f0, 1.0f0)  # Default bounds
end

"""
Generate reasonable tick positions for a given range
"""
function generate_tick_positions(min_val::Float32, max_val::Float32, approx_num_ticks::Int=8)::Vector{Float32}
    if min_val >= max_val
        return Float32[]
    end

    range_val = max_val - min_val
    # Find a nice step size
    raw_step = range_val / approx_num_ticks

    # Round to a nice number
    magnitude = 10.0f0^floor(log10(raw_step))
    normalized_step = raw_step / magnitude

    nice_step = if normalized_step <= 1.0f0
        1.0f0
    elseif normalized_step <= 2.0f0
        2.0f0
    elseif normalized_step <= 5.0f0
        5.0f0
    else
        10.0f0
    end

    step = nice_step * magnitude

    # Generate ticks
    ticks = Float32[]
    start_tick = ceil(min_val / step) * step

    current_tick = start_tick
    while current_tick <= max_val
        push!(ticks, current_tick)
        current_tick += step
    end

    return ticks
end


const SUPERSCRIPT_DIGITS = ('⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹')

"""
Convert an integer exponent to a unicode superscript string, e.g. `-3` → `"⁻³"`.
"""
function superscript_exponent(n::Integer)::String
    io = IOBuffer()
    n < 0 && print(io, '⁻')
    for d in string(abs(n))
        print(io, SUPERSCRIPT_DIGITS[d-'0'+1])
    end
    return String(take!(io))
end

"""
Number of decimals needed to represent values spaced `step` apart without
collapsing adjacent values onto the same string, e.g. `0.25` → 2, `0.1` → 1.
"""
function step_decimals(step::Float64)::Int
    step <= 0.0 && return 2
    d = max(0, ceil(Int, -log10(step) - 1e-9))
    # Increase until the step is (nearly) an integer multiple of 10^-d,
    # so e.g. a step of 0.25 gets 2 decimals, not 1. The tolerance is loose
    # enough to absorb Float32 noise accumulated during tick generation.
    while d < 12
        scaled = step * exp10(d)
        isapprox(scaled, round(scaled); rtol=1e-4, atol=1e-4) && break
        d += 1
    end
    return d
end

"""
    resolve_tick_offset(ticks::Vector{Float32}, significant_digits::Int)::Float64

Common offset to subtract from tick values before formatting; `0.0` when none
is needed. When ticks sit on a large shared value with comparatively tiny
spacing (deep zoom), no significant-digit budget can keep the labels short and
distinct — the offset is then displayed once as an axis annotation (see
[`format_axis_offset`](@ref)) and each tick label shows only `value - offset`.

The offset is the first tick exactly, so the residuals are clean multiples of
the tick step (`0`, `step`, `2·step`, …) and stay short.
"""
function resolve_tick_offset(ticks::Vector{Float32}, significant_digits::Int)::Float64
    length(ticks) < 2 && return 0.0
    step = Float64(ticks[2]) - Float64(ticks[1])
    step <= 0.0 && return 0.0
    magnitude = max(abs(Float64(ticks[1])), abs(Float64(ticks[end])))
    magnitude == 0.0 && return 0.0

    # Digits needed to write the largest tick at the step's resolution
    needed = floor(Int, log10(magnitude)) - floor(Int, log10(step)) + 1
    needed <= max(significant_digits, 1) && return 0.0

    return Float64(ticks[1])
end

"""
    tick_label_strings(ticks::Vector{Float32}, significant_digits::Int)

Produce the label string for every tick, plus the factored-out axis offset
(`0.0` when none is active). Single source of truth for tick label text: the
axis renderer draws these strings and the layout measures them, so the space
reserved for labels always matches what is drawn.
"""
function tick_label_strings(ticks::Vector{Float32}, significant_digits::Int)::Tuple{Vector{String},Float64}
    step = length(ticks) >= 2 ? ticks[2] - ticks[1] : nothing
    offset = resolve_tick_offset(ticks, significant_digits)
    labels = String[format_tick_label(Float64(t) - offset, significant_digits; step=step) for t in ticks]
    return labels, offset
end

"""
Format a factored-out axis offset for its annotation, e.g. `"+0.06682935"`.
Shown at full step resolution — the tick labels are exact residuals from this
value, so rounding it would misreport the axis.
"""
function format_axis_offset(offset::Float64, step::Float64)::String
    digits = floor(Int, log10(abs(offset))) - floor(Int, log10(abs(step))) + 3
    text = format_tick_label(offset, max(digits, 1))
    return offset > 0 ? "+" * text : text
end

"""
    format_tick_label(value::Real, significant_digits::Int; step=nothing, max_leading_zeros=1)::String

Format a tick value with at most `significant_digits` significant digits.
Values use plain decimal notation while the integer part stays within the
significant-digit budget; values too large for that, or with more than
`max_leading_zeros` zeros between the decimal point and the first significant
digit (e.g. `0.008917` at the default of 1), use scientific notation `m×10ⁿ`
with a unicode superscript exponent.

When `step` (the spacing between adjacent ticks) is given, labels always carry
enough digits to keep adjacent ticks distinct, even where that exceeds
`significant_digits`.
"""
function format_tick_label(value::Real, significant_digits::Int; step::Union{Real,Nothing}=nothing, max_leading_zeros::Int=1)::String
    v = Float64(value)
    (isnan(v) || isinf(v)) && return string(v)
    v == 0.0 && return "0"
    # Values far below the tick resolution are zero plus float noise
    step !== nothing && abs(v) < abs(Float64(step)) * 1e-2 && return "0"

    sig = max(significant_digits, 1)
    exponent = floor(Int, log10(abs(v)))

    # Zeros between the decimal point and the first significant digit (0 for |v| ≥ 0.1)
    leading_zeros = max(-exponent - 1, 0)

    # Plain decimal notation while the integer part fits the budget and the
    # leading zeros stay readable
    if leading_zeros <= max_leading_zeros && exponent < sig
        decimals = step === nothing ? clamp(sig - 1 - exponent, 0, 12) : step_decimals(Float64(step))
        if step !== nothing
            # Ticks may sit off the step grid (e.g. 0.5, 1.5, … with step 1):
            # add decimals until the label is faithful to the value
            while decimals < 12 && abs(round(v, digits=decimals) - v) > Float64(step) * 1e-3
                decimals += 1
            end
        end
        rounded = round(v, digits=decimals)
        if rounded != 0.0
            return decimals == 0 ? string(round(Int, v)) : string(rounded)
        end
    end

    # Scientific notation: m×10ⁿ
    mantissa = v / exp10(exponent)
    decimals = if step === nothing
        clamp(sig - 1, 0, 12)
    else
        # Enough mantissa decimals to resolve the tick spacing
        clamp(exponent - floor(Int, log10(Float64(step)) + 1e-9), 0, 12)
    end
    m = round(mantissa, digits=decimals)
    if abs(m) >= 10.0  # Rounding pushed the mantissa into the next decade
        m /= 10.0
        exponent += 1
    end
    # Integer mantissas drop the superfluous ".0" (1×10⁻⁵, not 1.0×10⁻⁵)
    m_str = (decimals == 0 || m == round(m)) ? string(round(Int, m)) : string(m)
    return string(m_str, "×10", superscript_exponent(exponent))
end

"""
Cull point data to only include points within the specified bounds.
Returns culled x and y data arrays.
"""
function cull_point_data(x_data::Vector{Float32}, y_data::Vector{Float32},
    x_min::Float32, x_max::Float32, y_min::Float32, y_max::Float32)
    if length(x_data) != length(y_data)
        return Float32[], Float32[]
    end

    culled_x = Float32[]
    culled_y = Float32[]

    for i in 1:length(x_data)
        x_val = x_data[i]
        y_val = y_data[i]

        # Include point if it's within bounds
        if x_val >= x_min && x_val <= x_max && y_val >= y_min && y_val <= y_max
            push!(culled_x, x_val)
            push!(culled_y, y_val)
        end
    end

    return culled_x, culled_y
end

"""
Cull line data and clip line segments to viewport bounds using proper interpolation.
This function clips line segments at the exact viewport boundaries to prevent 
lines from extending outside the visible area.
Returns culled x and y data arrays with clipped segments.
"""
function cull_line_data(x_data::Vector{Float32}, y_data::Vector{Float32},
    x_min::Float32, x_max::Float32, y_min::Float32, y_max::Float32)
    if length(x_data) != length(y_data) || length(x_data) < 2
        return Float32[], Float32[]
    end

    culled_x = Float32[]
    culled_y = Float32[]

    # Helper function to check if a point is inside bounds
    function point_in_bounds(x::Float32, y::Float32)::Bool
        return x >= x_min && x <= x_max && y >= y_min && y <= y_max
    end

    # Cohen-Sutherland line clipping algorithm
    # Compute outcode for a point relative to the clipping rectangle
    function compute_outcode(x::Float32, y::Float32)::UInt8
        code = 0x00
        if x < x_min
            code |= 0x01  # LEFT
        elseif x > x_max
            code |= 0x02  # RIGHT
        end
        if y < y_min
            code |= 0x04  # BOTTOM
        elseif y > y_max
            code |= 0x08  # TOP
        end
        return code
    end

    # Clip a line segment to the viewport bounds
    function clip_line_segment(x1::Float32, y1::Float32, x2::Float32, y2::Float32)
        outcode1 = compute_outcode(x1, y1)
        outcode2 = compute_outcode(x2, y2)

        accept = false

        while true
            if (outcode1 | outcode2) == 0  # Both points inside
                accept = true
                break
            elseif (outcode1 & outcode2) != 0  # Both points on same side outside
                break  # Trivially reject
            else
                # At least one point is outside - clip it
                x = 0.0f0
                y = 0.0f0

                # Pick the point that is outside
                outcode_out = outcode1 != 0 ? outcode1 : outcode2

                # Find intersection point using line equation
                # y = y1 + slope * (x - x1), where slope = (y2 - y1) / (x2 - x1)
                if (outcode_out & 0x08) != 0  # TOP
                    x = x1 + (x2 - x1) * (y_max - y1) / (y2 - y1)
                    y = y_max
                elseif (outcode_out & 0x04) != 0  # BOTTOM
                    x = x1 + (x2 - x1) * (y_min - y1) / (y2 - y1)
                    y = y_min
                elseif (outcode_out & 0x02) != 0  # RIGHT
                    y = y1 + (y2 - y1) * (x_max - x1) / (x2 - x1)
                    x = x_max
                elseif (outcode_out & 0x01) != 0  # LEFT
                    y = y1 + (y2 - y1) * (x_min - x1) / (x2 - x1)
                    x = x_min
                end

                # Update the point that was outside and its outcode
                if outcode_out == outcode1
                    x1 = x
                    y1 = y
                    outcode1 = compute_outcode(x1, y1)
                else
                    x2 = x
                    y2 = y
                    outcode2 = compute_outcode(x2, y2)
                end
            end
        end

        if accept
            return true, x1, y1, x2, y2
        else
            return false, 0.0f0, 0.0f0, 0.0f0, 0.0f0
        end
    end

    # Process line segments
    for i in 1:(length(x_data)-1)
        x1, y1 = x_data[i], y_data[i]
        x2, y2 = x_data[i+1], y_data[i+1]

        # Skip if either point is NaN
        if isnan(x1) || isnan(y1) || isnan(x2) || isnan(y2)
            if !isempty(culled_x) && !isnan(culled_x[end])
                # Add NaN to break line continuity
                push!(culled_x, NaN32)
                push!(culled_y, NaN32)
            end
            continue
        end

        # Clip the line segment to viewport bounds
        clipped, cx1, cy1, cx2, cy2 = clip_line_segment(x1, y1, x2, y2)

        if clipped
            # Check if we need to start a new line segment
            need_new_segment = false
            if isempty(culled_x) || isnan(culled_x[end])
                need_new_segment = true
            else
                # Check if this segment connects to the previous one
                last_x, last_y = culled_x[end], culled_y[end]
                if abs(last_x - cx1) > 1e-6 || abs(last_y - cy1) > 1e-6
                    need_new_segment = true
                end
            end

            if need_new_segment
                # Start new segment
                if !isempty(culled_x) && !isnan(culled_x[end])
                    push!(culled_x, NaN32)
                    push!(culled_y, NaN32)
                end
                push!(culled_x, cx1)
                push!(culled_y, cy1)
            end

            # Add the end point
            push!(culled_x, cx2)
            push!(culled_y, cy2)
        else
            # Segment is completely outside - break line continuity
            if !isempty(culled_x) && !isnan(culled_x[end])
                push!(culled_x, NaN32)
                push!(culled_y, NaN32)
            end
        end
    end

    return culled_x, culled_y
end