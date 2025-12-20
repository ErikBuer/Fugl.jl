mutable struct HoverInfo
    is_hovered::Bool
    hover_start_time::Float64
    hover_duration::Float64
    last_frame_hovered::Int
    hover_count::Int
    is_pressed::Bool  # Track if mouse is currently pressed down on this component
end

mutable struct HoverRegistry
    current_frame::Int
    current_time::Float64
    hover_map::Dict{UInt64,HoverInfo}
    newly_hovered::Set{UInt64}
    newly_unhovered::Set{UInt64}
end

const HOVER_REGISTRY = Ref{HoverRegistry}()

function init_hover_registry!()
    HOVER_REGISTRY[] = HoverRegistry(0, 0.0, Dict{UInt64,HoverInfo}(), Set{UInt64}(), Set{UInt64}())
end

function start_frame_hover!(frame::Int, current_time::Float64)
    registry = HOVER_REGISTRY[]
    registry.current_frame = frame
    registry.current_time = current_time
    empty!(registry.newly_hovered)
    empty!(registry.newly_unhovered)
end

@inline function component_id(x::Float32, y::Float32, width::Float32, height::Float32)::UInt64
    # Round to avoid floating point precision issues
    return hash((round(Int, x), round(Int, y), round(Int, width), round(Int, height)))
end

function update_hover_state!(comp_id::UInt64, is_currently_hovered::Bool)
    registry = HOVER_REGISTRY[]

    if haskey(registry.hover_map, comp_id)
        info = registry.hover_map[comp_id]
        was_hovered = info.is_hovered

        if is_currently_hovered && !was_hovered
            # Just started hovering
            info.hover_start_time = registry.current_time
            info.hover_count += 1
            push!(registry.newly_hovered, comp_id)
        elseif !is_currently_hovered && was_hovered
            # Just stopped hovering
            info.hover_duration += registry.current_time - info.hover_start_time
            push!(registry.newly_unhovered, comp_id)
        elseif is_currently_hovered
            # Still hovering - update duration
            info.hover_duration = registry.current_time - info.hover_start_time
        end

        info.is_hovered = is_currently_hovered
        info.last_frame_hovered = is_currently_hovered ? registry.current_frame : info.last_frame_hovered
    else
        # First time seeing this component
        registry.hover_map[comp_id] = HoverInfo(
            is_currently_hovered,
            is_currently_hovered ? registry.current_time : 0.0,
            0.0,
            is_currently_hovered ? registry.current_frame : 0,
            is_currently_hovered ? 1 : 0,
            false  # is_pressed starts as false
        )

        if is_currently_hovered
            push!(registry.newly_hovered, comp_id)
        end
    end
end

# Query functions - optimized for performance
@inline function get_hover_info(x::Float32, y::Float32, width::Float32, height::Float32)::HoverInfo
    comp_id = component_id(x, y, width, height)
    registry = HOVER_REGISTRY[]

    if haskey(registry.hover_map, comp_id)
        return registry.hover_map[comp_id]
    else
        return HoverInfo(false, 0.0, 0.0, 0, 0, false)  # include is_pressed=false
    end
end

@inline function is_hovered(x::Float32, y::Float32, width::Float32, height::Float32)::Bool
    comp_id = component_id(x, y, width, height)
    registry = HOVER_REGISTRY[]

    if haskey(registry.hover_map, comp_id)
        return registry.hover_map[comp_id].is_hovered
    else
        return false
    end
end

@inline function hover_duration(x::Float32, y::Float32, width::Float32, height::Float32)::Float64
    return get_hover_info(x, y, width, height).hover_duration
end

@inline function just_hovered(x::Float32, y::Float32, width::Float32, height::Float32)::Bool
    comp_id = component_id(x, y, width, height)
    return comp_id in HOVER_REGISTRY[].newly_hovered
end

@inline function just_unhovered(x::Float32, y::Float32, width::Float32, height::Float32)::Bool
    comp_id = component_id(x, y, width, height)
    return comp_id in HOVER_REGISTRY[].newly_unhovered
end

# Pressed state functions
function update_pressed_state!(comp_id::UInt64, is_currently_pressed::Bool)
    registry = HOVER_REGISTRY[]

    if haskey(registry.hover_map, comp_id)
        registry.hover_map[comp_id].is_pressed = is_currently_pressed
    else
        # Create new entry if it doesn't exist
        registry.hover_map[comp_id] = HoverInfo(false, 0.0, 0.0, 0, 0, is_currently_pressed)
    end
end

@inline function is_pressed(x::Float32, y::Float32, width::Float32, height::Float32)::Bool
    comp_id = component_id(x, y, width, height)
    registry = HOVER_REGISTRY[]

    if haskey(registry.hover_map, comp_id)
        return registry.hover_map[comp_id].is_pressed
    else
        return false
    end
end