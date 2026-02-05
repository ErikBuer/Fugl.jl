include("modal_style.jl")
include("modal_state.jl")

struct ModalView <: AbstractView
    background::AbstractView    # The background contents being covered by the modal
    child::AbstractView         # The content to display in the modal
    child_width::Float32        # Width of the modal content
    child_height::Float32       # Height of the modal content
    state::ModalState           # Position state
    style::ModalStyle           # Appearance style
    on_state_change::Function   # Callback for state changes
    on_click_outside::Function  # Callback for clicking outside the modal
    capture_clicks_outside::Bool          # Whether to capture clicks outside the modal to prevent them from passing through
end

function Modal(
    background::AbstractView,
    child::AbstractView;
    child_width::Real=200.0f0,
    child_height::Real=100.0f0,
    state::ModalState=ModalState(),
    style::ModalStyle=ModalStyle(),
    on_state_change::Function=(new_state) -> nothing,
    on_click_outside::Function=() -> nothing,
    capture_clicks_outside::Bool=false
)
    return ModalView(background, child, Float32(child_width), Float32(child_height), state, style, on_state_change, on_click_outside, capture_clicks_outside)
end

function measure(view::ModalView)::Tuple{Float32,Float32}
    # Modal takes the size of the background
    return measure(view.background)
end

function apply_layout(view::ModalView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function interpret_view(view::ModalView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # First, render the background content
    interpret_view(view.background, x, y, width, height, projection_matrix, mouse_x, mouse_y)

    # Draw the darkened overlay
    background_vertices = generate_rectangle_vertices(x, y, width, height)
    draw_rectangle(background_vertices, view.style.background_color, projection_matrix)

    # Calculate modal position constrained within parent bounds
    modal_x = x + view.state.offset_x
    modal_y = y + view.state.offset_y
    modal_width = view.child_width
    modal_height = view.child_height

    # Constrain modal to stay within parent bounds
    modal_x = clamp(modal_x, x, x + width - modal_width)
    modal_y = clamp(modal_y, y, y + height - modal_height)

    # Interpret the modal child at the modal position using the full modal dimensions
    # The modal dimensions from state define the available space for the child
    interpret_view(view.child, modal_x, modal_y, modal_width, modal_height, projection_matrix, mouse_x, mouse_y)
end

function detect_click(view::ModalView, input_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    mouse_x, mouse_y = Float32(input_state.x), Float32(input_state.y)

    # Calculate modal position
    modal_x = x + view.state.offset_x
    modal_y = y + view.state.offset_y
    modal_width = view.child_width
    modal_height = view.child_height

    # Constrain modal to stay within parent bounds
    modal_x = clamp(modal_x, x, x + width - modal_width)
    modal_y = clamp(modal_y, y, y + height - modal_height)

    # High z-order for overlay content
    z = Int32(parent_z + 1000)

    # Check if mouse is over the modal content
    mouse_over_modal = (mouse_x >= modal_x && mouse_x <= modal_x + modal_width &&
                        mouse_y >= modal_y && mouse_y <= modal_y + modal_height)

    # Handle drag start - store initial mouse offset from modal position
    if input_state.mouse_down[LeftButton] && mouse_over_modal && !input_state.is_dragging[LeftButton]
        # Store the offset from modal top-left to mouse position when drag starts
        drag_offset_x = mouse_x - modal_x
        drag_offset_y = mouse_y - modal_y

        new_state = ModalState(view.state;
            drag_offset_x=drag_offset_x,
            drag_offset_y=drag_offset_y
        )

        view.on_state_change(new_state)
    end

    # Handle dragging
    if input_state.button_state[LeftButton] == IsPressed && input_state.is_dragging[LeftButton]
        if mouse_over_modal || !isnothing(input_state.last_drag_position[LeftButton])
            # Calculate new modal position maintaining the drag offset
            new_offset_x = mouse_x - x - view.state.drag_offset_x
            new_offset_y = mouse_y - y - view.state.drag_offset_y

            # Constrain to parent bounds
            new_offset_x = clamp(new_offset_x, 0.0f0, width - modal_width)
            new_offset_y = clamp(new_offset_y, 0.0f0, height - modal_height)

            # Update state only if position changed
            if new_offset_x != view.state.offset_x || new_offset_y != view.state.offset_y
                new_state = ModalState(view.state;
                    offset_x=new_offset_x,
                    offset_y=new_offset_y
                )

                return ClickResult(z, () -> view.on_state_change(new_state))
            end
        end
    end

    child_result = detect_click(view.child, input_state, modal_x, modal_y, modal_width, modal_height, z)
    if !isnothing(child_result)
        unfocus_components(view.background, input_state, x, y, width, height, Int32(0))
        return child_result
    end

    # Click inside component but outside of modal. Typically used to close the modal when clicking outside of it.
    if input_state.mouse_down[LeftButton] && inside_component(view, x, y, width, height, mouse_x, mouse_y) && !mouse_over_modal
        view.on_click_outside()

        if view.capture_clicks_outside
            unfocus_components(view.background, input_state, x, y, width, height, Int32(0))
        end

        return detect_click(view.background, input_state, x, y, width, height, Int32(parent_z + 1))
    end

    return nothing
end

"""
Defocus all components in a view by simulating a click outside their bounds.
"""
function unfocus_components(view::AbstractView, input_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)
    # Save original state
    original_x = input_state.x
    original_y = input_state.y
    original_mouse_down = input_state.mouse_down[LeftButton]

    # Simulate a click outside all components
    input_state.x = -1000.0
    input_state.y = -1000.0
    input_state.mouse_down[LeftButton] = true

    # Trigger detect_click to process the defocus
    detect_click(view, input_state, x, y, width, height, parent_z)

    # Restore original state
    input_state.x = original_x
    input_state.y = original_y
    input_state.mouse_down[LeftButton] = original_mouse_down
end