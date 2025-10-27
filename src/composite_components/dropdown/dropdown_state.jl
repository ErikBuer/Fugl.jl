struct DropdownState
    options::Vector{String}      # Available options
    selected_index::Int          # Currently selected option (1-based, 0 = none selected)
    is_open::Bool               # Whether dropdown is expanded
    hover_index::Int            # Which item is being hovered (0 = none)
    is_hovered::Bool            # Whether the dropdown button itself is hovered
end

function DropdownState(
    options::Vector{String}=String[];
    selected_index::Int=0,
    is_open::Bool=false,
    hover_index::Int=0,
    is_hovered::Bool=false
)
    return DropdownState(options, selected_index, is_open, hover_index, is_hovered)
end

# Constructor to copy state with changes (like EditorState)
function DropdownState(state::DropdownState;
    options=state.options,
    selected_index=state.selected_index,
    is_open=state.is_open,
    hover_index=state.hover_index,
    is_hovered=state.is_hovered)
    return DropdownState(options, selected_index, is_open, hover_index, is_hovered)
end