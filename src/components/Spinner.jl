# Default spinner symbols

const DEFAULT_SPINNER_SYMBOLS = ['', '', '', '', '', '', '', '', '', '', '', '']


# Alternative spinner symbol sets
const DOTS_SPINNER = ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷']
const DOTS_SPINNER_LONG = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
const ARROWS_SPINNER = ['←', '↖', '↑', '↗', '→', '↘', '↓', '↙']
const BARS_SPINNER = ['|', '/', '-', '\\']
const CIRCLE_SPINNER = ['', '', '', '', '', '', '']

struct SpinnerState
    current_index::Int
    last_update_time::Float64
    is_spinning::Bool
end

SpinnerState() = SpinnerState(1, 0.0, true)

struct SpinnerView <: AbstractView
    symbols::Vector{Char}
    interval_seconds::Float64
    text_style::TextStyle
    state::SpinnerState
    on_state_change::Function
end

"""
Create a Spinner component

# Arguments
- `symbols::Vector{Char}`: Array of Unicode characters to cycle through
- `interval_seconds::Float64`: Time between symbol changes (default: 0.1)
- `text_style::TextStyle`: Text styling for the spinner symbol
- `state::SpinnerState`: Current spinner state 
- `is_spinning::Bool`: Whether the spinner should animate
- `on_state_change::Function`: Callback when spinner state changes
"""
function Spinner(
    symbols::Vector{Char}=DEFAULT_SPINNER_SYMBOLS;
    interval_seconds::Float64=0.1,
    text_style::TextStyle=TextStyle(),
    state::SpinnerState=SpinnerState(),
    on_state_change::Function=(new_state) -> nothing
)
    return SpinnerView(
        symbols,
        interval_seconds,
        text_style,
        state,
        on_state_change
    )
end

function measure(view::SpinnerView)::Tuple{Float32,Float32}
    # Measure using the current symbol
    current_symbol = string(view.symbols[view.state.current_index])
    temp_text = Text(current_symbol, style=view.text_style)
    return measure(temp_text)
end

function measure_width(view::SpinnerView, available_height::Float32)::Float32
    current_symbol = string(view.symbols[view.state.current_index])
    temp_text = Text(current_symbol, style=view.text_style)
    return measure_width(temp_text, available_height)
end

function measure_height(view::SpinnerView, available_width::Float32)::Float32
    current_symbol = string(view.symbols[view.state.current_index])
    temp_text = Text(current_symbol, style=view.text_style)
    return measure_height(temp_text, available_width)
end

function interpret_view(view::SpinnerView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    current_state = view.state

    # Update animation if spinning is enabled
    if current_state.is_spinning && length(view.symbols) > 1
        current_time = time()

        # Check if it's time to advance to the next symbol
        if current_time - current_state.last_update_time >= view.interval_seconds
            new_index = (current_state.current_index % length(view.symbols)) + 1
            new_state = SpinnerState(
                new_index,
                current_time,
                current_state.is_spinning
            )

            # Notify callback - caller is responsible for updating state
            view.on_state_change(new_state)
        end
    end

    # Render the current symbol using Text component
    current_symbol = string(view.symbols[view.state.current_index])
    text_component = Text(current_symbol, style=view.text_style)
    interpret_view(text_component, x, y, width, height, projection_matrix, mouse_x, mouse_y)
end

function detect_click(view::SpinnerView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    # Spinners typically don't handle clicks, but forward to Text behavior
    current_symbol = string(view.symbols[view.state.current_index])
    text_component = Text(current_symbol, style=view.text_style)
    return detect_click(text_component, mouse_state, x, y, width, height, parent_z)
end

"""
Delegate preferred width to the text component.
"""
function preferred_width(view::SpinnerView)::Bool
    current_symbol = string(view.symbols[view.state.current_index])
    temp_text = Text(current_symbol, style=view.text_style)
    return preferred_width(temp_text)
end

"""
Delegate preferred height to the text component.
"""
function preferred_height(view::SpinnerView)::Bool
    current_symbol = string(view.symbols[view.state.current_index])
    temp_text = Text(current_symbol, style=view.text_style)
    return preferred_height(temp_text)
end

# Convenience functions for different spinner types
"""Create a dots spinner with Braille patterns"""
DotsSpinner(args...; kwargs...) = Spinner(DOTS_SPINNER, args...; kwargs...)

"""Create an arrows spinner"""
ArrowsSpinner(args...; kwargs...) = Spinner(ARROWS_SPINNER, args...; kwargs...)

"""Create a simple bars spinner"""
BarsSpinner(args...; kwargs...) = Spinner(BARS_SPINNER, args...; kwargs...)

"""Create a long Braille-dots spinner"""
DotsLongSpinner(args...; kwargs...) = Spinner(DOTS_SPINNER_LONG, args...; kwargs...)

"""Create a circle/arc spinner"""
CircleSpinner(args...; kwargs...) = Spinner(CIRCLE_SPINNER, args...; kwargs...)

