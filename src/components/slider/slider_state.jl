"""
State management for slider components.
"""

struct SliderState{T<:Real}
    value::T
    min_value::T
    max_value::T
    is_dragging::Bool
    interaction_state::InteractionState
end

"""
Create a new SliderState with the given value within the specified range.
"""
function SliderState(value::T, min_value::T, max_value::T; is_dragging::Bool=false, interaction_state::InteractionState=InteractionState()) where T<:Real
    clamped_value = clamp(value, min_value, max_value)
    return SliderState(clamped_value, min_value, max_value, is_dragging, interaction_state)
end

"""
Create a new SliderState with automatic type conversion to the specified output type.
Useful for creating sliders that output specific types (e.g., Int for discrete values).
"""
function SliderState(::Type{T}, value, min_value, max_value; is_dragging::Bool=false, interaction_state::InteractionState=InteractionState()) where T<:Real
    converted_value = T(value)
    converted_min = T(min_value)
    converted_max = T(max_value)
    clamped_value = clamp(converted_value, converted_min, converted_max)
    return SliderState(clamped_value, converted_min, converted_max, is_dragging, interaction_state)
end

"""
Create a new SliderState from an existing state with keyword-based modifications.
"""
function SliderState(state::SliderState{T};
    value=state.value,
    min_value=state.min_value,
    max_value=state.max_value,
    is_dragging=state.is_dragging,
    interaction_state=state.interaction_state) where T<:Real

    clamped_value = clamp(value, min_value, max_value)
    return SliderState(clamped_value, min_value, max_value, is_dragging, interaction_state)
end

"""
Apply discrete step snapping to a value.
Returns the value snapped to the nearest step if steps are defined.
For discrete steps (Int), automatically rounds to the appropriate output type.
"""
function apply_step_snapping(value::T, min_value::T, max_value::T, steps::Union{Nothing,Int,T}) where T<:Real
    if steps === nothing
        return value  # No snapping
    end

    if steps isa Int
        # Discrete number of steps
        if steps <= 1
            return min_value  # Edge case: if 1 or fewer steps, return min
        end

        # For discrete steps, we map continuous input to discrete output
        step_size = (max_value - min_value) / (steps - 1)
        step_index = round(Int, (value - min_value) / step_size)
        step_index = clamp(step_index, 0, steps - 1)

        # Calculate the discrete value
        discrete_value = min_value + step_index * step_size

        # For integer types, ensure we return properly rounded integers
        if T <: Integer
            return T(round(discrete_value))
        else
            return discrete_value
        end
    else
        # Fixed step size
        if steps <= 0
            return value  # Edge case: invalid step size, no snapping
        end
        step_count = round(Int, (value - min_value) / steps)
        stepped_value = min_value + step_count * steps

        # Clamp to range and handle integer types
        clamped_value = clamp(stepped_value, min_value, max_value)
        return T <: Integer ? T(round(clamped_value)) : clamped_value
    end
end