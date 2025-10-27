@enum LineStyle begin
    SOLID = 0
    DASH = 1
    DOT = 2
    DASHDOT = 3
end

function Base.Float32(arg::Fugl.LineStyle)
    return Float32(Int(arg))
end