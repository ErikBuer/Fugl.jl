"""
Line cap styles for line endpoints.
"""
@enum LineCap begin
    BUTT_CAP      # Line stops at vertex
    SQUARE_CAP    # Line extends width/2 for proper right angles
    ROUND_CAP     # Circle-like shape at the end for continuous joints
end

function Base.Float32(arg::LineCap)
    return Float32(Int(arg))
end

# Display name mapping for prettier UI labels
const LINE_CAP_DISPLAY_NAMES = Dict(
    BUTT_CAP => "Butt",
    SQUARE_CAP => "Square",
    ROUND_CAP => "Round"
)

# Convenience functions for LineCap 
line_cap_values() = enum_values(LineCap)
line_cap_names() = enum_display_names(LineCap, LINE_CAP_DISPLAY_NAMES)
line_cap_index(cap::LineCap) = enum_index(cap)