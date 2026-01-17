"""
Generic function to get all enum values as a vector.
"""
function enum_values(::Type{T}) where T<:Enum
    return collect(instances(T))
end

"""
Generic function to get display names for enum values.
Uses a display name mapping if provided, otherwise converts enum names to strings.
"""
function enum_display_names(::Type{T}, display_map::Dict{T,String}=Dict{T,String}()) where T<:Enum
    values = enum_values(T)
    if isempty(display_map)
        # Default: convert enum name to string
        return [string(Symbol(val)) for val in values]
    else
        # Use provided display mapping
        return [get(display_map, val, string(Symbol(val))) for val in values]
    end
end

"""
Generic function to get the index of an enum value (1-based).
"""
function enum_index(value::T) where T<:Enum
    values = enum_values(T)
    return findfirst(==(value), values)
end

"""
Generic function to convert string to enum value.
"""
function string_to_enum(::Type{T}, str::String) where T<:Enum
    return eval(Symbol(str))
end