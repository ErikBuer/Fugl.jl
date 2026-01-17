"""
Enumeration for different line patterns.
"""
@enum LinePattern begin
    SOLID = 0
    DASH = 1
    DOT = 2
    DASHDOT = 3
end

function Base.Float32(arg::LinePattern)
    return Float32(Int(arg))
end

# Display name mapping for prettier UI labels
const LINE_PATTERN_DISPLAY_NAMES = Dict(
    SOLID => "Solid",
    DASH => "Dash",
    DOT => "Dot",
    DASHDOT => "Dash-Dot"
)

# Convenience functions for LinePattern
line_pattern_values() = enum_values(LinePattern)
line_pattern_names() = enum_display_names(LinePattern, LINE_PATTERN_DISPLAY_NAMES)
line_pattern_index(pattern::LinePattern) = enum_index(pattern)