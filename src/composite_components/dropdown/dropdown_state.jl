struct DropdownState
    options::Vector{String}      # Available options
    selected_index::Int          # Currently selected option (1-based, 0 = none selected)
    is_open::Bool               # Whether dropdown is expanded
    hover_index::Int            # Which item is being hovered (0 = none)
    is_hovered::Bool            # Whether the dropdown button itself is hovered
    scroll_offset::Int          # First visible item index (0-based for easier math)
    search_text::String         # Current search filter text
end

function DropdownState(
    options::Vector{String}=String[];
    selected_index::Int=0,
    is_open::Bool=false,
    hover_index::Int=0,
    is_hovered::Bool=false,
    scroll_offset::Int=0,
    search_text::String=""
)
    return DropdownState(options, selected_index, is_open, hover_index, is_hovered, scroll_offset, search_text)
end

# Constructor to copy state with changes
function DropdownState(state::DropdownState;
    options=state.options,
    selected_index=state.selected_index,
    is_open=state.is_open,
    hover_index=state.hover_index,
    is_hovered=state.is_hovered,
    scroll_offset=state.scroll_offset,
    search_text=state.search_text)
    return DropdownState(options, selected_index, is_open, hover_index, is_hovered, scroll_offset, search_text)
end

# Get filtered options based on search text
function get_filtered_options(state::DropdownState)::Vector{String}
    if isempty(state.search_text)
        return state.options
    else
        # Case-insensitive search
        search_lower = lowercase(state.search_text)
        return filter(option -> contains(lowercase(option), search_lower), state.options)
    end
end

# Get the actual option index from filtered index
function get_actual_option_index(state::DropdownState, filtered_index::Int)::Int
    if isempty(state.search_text)
        return filtered_index
    else
        filtered_options = get_filtered_options(state)
        if filtered_index >= 1 && filtered_index <= length(filtered_options)
            filtered_option = filtered_options[filtered_index]
            return findfirst(x -> x == filtered_option, state.options)
        else
            return 0
        end
    end
end