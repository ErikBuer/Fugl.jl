"""
    TableState(column_widths, auto_size, cache_id)

Represents the state of a table, including column widths and sizing behavior.

Fields:
- `column_widths`: Vector of column widths in pixels. If nothing, will be auto-calculated.
- `auto_size`: Bool, whether to automatically size columns to fit content.
- `cache_id`: Unique identifier for table cache. Not user managed.
"""
struct TableState
    column_widths::Union{Vector{Float32},Nothing}
    auto_size::Bool
    cache_id::UInt64
end

"""
Create a new TableState from an existing state with keyword-based modifications.
"""
function TableState(state::TableState;
    column_widths=state.column_widths,
    auto_size=state.auto_size,
    cache_id=state.cache_id # Not user managed
)
    return TableState(
        column_widths,
        auto_size,
        cache_id
    )
end

"""
Create TableState with explicit column widths
"""
function TableState(column_widths::Vector{Float32}; auto_size::Bool=false)
    return TableState(column_widths, auto_size, rand(UInt64))
end

"""
Create TableState with sensible defaults
"""
function TableState(;
    auto_size::Bool=true,
    column_widths::Union{Vector{Float32},Nothing}=nothing
)
    return TableState(column_widths, auto_size, rand(UInt64))
end