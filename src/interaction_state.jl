"""
Interaction state management for GUI components.

Provides a common structure for tracking user interactions like hover, press, focus, etc.
"""
struct InteractionState
    is_hovered::Bool
    is_pressed::Bool
    is_focused::Bool
    hover_duration::Float64
    hover_start_time::Float64
    just_hovered::Bool
    just_unhovered::Bool
    just_pressed::Bool
    just_released::Bool
end

"""
Create a new InteractionState with default (inactive) values.
"""
function InteractionState(;
    is_hovered::Bool=false,
    is_pressed::Bool=false,
    is_focused::Bool=false,
    hover_duration::Float64=0.0,
    hover_start_time::Float64=0.0,
    just_hovered::Bool=false,
    just_unhovered::Bool=false,
    just_pressed::Bool=false,
    just_released::Bool=false
)
    return InteractionState(is_hovered, is_pressed, is_focused, hover_duration, hover_start_time, just_hovered, just_unhovered, just_pressed, just_released)
end

"""
Create a new InteractionState from an existing state with keyword-based modifications.
"""
function InteractionState(state::InteractionState;
    is_hovered=state.is_hovered,
    is_pressed=state.is_pressed,
    is_focused=state.is_focused,
    hover_duration=state.hover_duration,
    hover_start_time=state.hover_start_time,
    just_hovered=state.just_hovered,
    just_unhovered=state.just_unhovered,
    just_pressed=state.just_pressed,
    just_released=state.just_released
)
    return InteractionState(is_hovered, is_pressed, is_focused, hover_duration, hover_start_time, just_hovered, just_unhovered, just_pressed, just_released)
end

"""
Update interaction state based on current mouse/input state.
Returns a new InteractionState with updated values.
"""
function update_interaction_state(
    current_state::Union{Nothing,InteractionState};
    is_mouse_inside::Bool,
    is_mouse_pressed::Bool,
    current_time::Float64
)::InteractionState

    if current_state === nothing
        # First time - create new state
        if is_mouse_inside
            return InteractionState(
                is_hovered=true,
                is_pressed=is_mouse_pressed,
                is_focused=is_mouse_inside,
                hover_start_time=current_time,
                hover_duration=0.0,
                just_hovered=true,
                just_pressed=is_mouse_pressed
            )
        else
            return InteractionState()
        end
    end

    # Calculate "just" transitions
    just_hovered = is_mouse_inside && !current_state.is_hovered
    just_unhovered = !is_mouse_inside && current_state.is_hovered
    just_pressed = is_mouse_pressed && !current_state.is_pressed
    just_released = !is_mouse_pressed && current_state.is_pressed

    # Calculate hover duration
    new_hover_start_time = if just_hovered
        current_time
    elseif current_state.is_hovered && is_mouse_inside
        current_state.hover_start_time
    else
        0.0
    end

    new_hover_duration = if is_mouse_inside
        current_time - new_hover_start_time
    else
        current_state.hover_duration  # Preserve last duration when not hovering
    end

    return InteractionState(
        is_hovered=is_mouse_inside,
        is_pressed=is_mouse_pressed,
        is_focused=is_mouse_inside,  # For now, focus follows hover
        hover_duration=new_hover_duration,
        hover_start_time=new_hover_start_time,
        just_hovered=just_hovered,
        just_unhovered=just_unhovered,
        just_pressed=just_pressed,
        just_released=just_released
    )
end

"""
Helper function to check if interaction state indicates any active interaction.
"""
function is_interacting(state::Union{Nothing,InteractionState})::Bool
    state === nothing && return false
    return state.is_hovered || state.is_pressed || state.is_focused
end

"""
Helper function to get hover duration safely.
"""
function get_hover_duration(state::Union{Nothing,InteractionState})::Float64
    state === nothing && return 0.0
    return state.hover_duration
end