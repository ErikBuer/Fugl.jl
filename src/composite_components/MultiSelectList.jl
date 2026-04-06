"""
    MultiSelectListStyle(;
        item_height, text_style, text_style_selected,
        item_background, item_hover_color,
        item_selected_color, item_selected_hover_color,
        border_color, border_width, padding, corner_radius
    )

Visual style for `MultiSelectList`.
"""
struct MultiSelectListStyle
    item_height::Float32
    text_style::TextStyle
    text_style_selected::Union{Nothing,TextStyle}
    item_background::Vec4{Float32}
    item_hover_color::Vec4{Float32}
    item_selected_color::Vec4{Float32}
    item_selected_hover_color::Vec4{Float32}
    border_color::Vec4{Float32}
    border_width::Float32
    padding::Float32
    corner_radius::Float32
end

function MultiSelectListStyle(;
    item_height::Float32=28.0f0,
    text_style::TextStyle=TextStyle(),
    text_style_selected::Union{Nothing,TextStyle}=nothing,
    item_background::Vec4{Float32}=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0),
    item_hover_color::Vec4{Float32}=Vec4{Float32}(0.88f0, 0.91f0, 0.97f0, 1.0f0),
    item_selected_color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.5f0, 0.9f0, 1.0f0),
    item_selected_hover_color::Vec4{Float32}=Vec4{Float32}(0.27f0, 0.55f0, 0.95f0, 1.0f0),
    border_color::Vec4{Float32}=Vec4{Float32}(0.5f0, 0.5f0, 0.5f0, 1.0f0),
    border_width::Float32=1.0f0,
    padding::Float32=0.0f0,
    corner_radius::Float32=5.0f0,
)
    return MultiSelectListStyle(
        item_height, text_style, text_style_selected,
        item_background, item_hover_color,
        item_selected_color, item_selected_hover_color,
        border_color, border_width, padding, corner_radius,
    )
end

"""
    MultiSelectState(n_items; selected_indices = Set{Int}())

State for the `MultiSelectList` component.

- `selected_indices::Set{Int}`: 1-based indices of the currently selected options.
- `row_states::Vector{InteractionState}`: Per-row hover/press state for visual feedback.

## Example
```julia
options = ["Apple", "Banana", "Cherry"]
list_state = Ref(MultiSelectState(length(options)))
```
"""
struct MultiSelectState
    selected_indices::Set{Int}
    row_states::Vector{InteractionState}
end

function MultiSelectState(n_items::Int; selected_indices::Set{Int}=Set{Int}())
    return MultiSelectState(selected_indices, [InteractionState() for _ in 1:n_items])
end

function MultiSelectState(base::MultiSelectState;
    selected_indices=base.selected_indices,
    row_states=base.row_states,
)
    return MultiSelectState(selected_indices, row_states)
end

"""
    MultiSelectList(
        options::Vector{String},
        state::MultiSelectState;
        style::MultiSelectListStyle = MultiSelectListStyle(),
        on_state_change::Function = (new_state) -> nothing,
        on_change::Function = (selected_indices::Set{Int}) -> nothing,
    )

A form component displaying a list of items where multiple rows can be selected
by clicking. Selected rows are highlighted and deselect-able by clicking again.

The component has `preferred_height = true` and sizes to fit all its items.
Wrap in a `VerticalScrollArea` + `FixedHeight` when the list may be long.

## Arguments
- `options`: String labels for each row.
- `state`: Current component state — pass `my_state_ref[]`.
- `style`: Visual style.
- `on_state_change`: Called on every interaction (hover, click). Must update
  the state ref, e.g. `(new_state) -> list_state[] = new_state`.
- `on_change`: Called only when the selection changes. Receives the new
  `Set{Int}` of selected (1-based) indices.

## Example
```julia
options = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
list_state = Ref(MultiSelectState(length(options)))

function MyApp()
    MultiSelectList(
        options,
        list_state[];
        on_state_change = (new_state) -> list_state[] = new_state,
        on_change = (selected) -> println("Selected: ", collect(selected)),
    )
end
```
"""
function MultiSelectList(
    options::Vector{String},
    state::MultiSelectState;
    style::MultiSelectListStyle=MultiSelectListStyle(),
    on_state_change::Function=(new_state) -> nothing,
    on_change::Function=(selected_indices::Set{Int}) -> nothing,
)
    n = length(options)
    row_states = _multiselect_resize_states(state.row_states, n)
    initial_state = MultiSelectState(state; row_states=row_states)

    # Frame-local ref so callbacks within the same detect_click pass read the
    # latest state rather than the stale captured value.  Without this, when
    # the mouse moves from row A to row B in a single frame, row A's unhover
    # callback fires first (correct), but row B's hover callback then uses the
    # stale original row_states and inadvertently re-hovers row A.
    current_state = Ref(initial_state)

    function emit(new_state)
        current_state[] = new_state
        on_state_change(new_state)
    end

    rows = AbstractView[_multiselect_row(
        options[i], i, current_state, style, emit, on_change
    ) for i in 1:n]

    return BaseContainer(
        IntrinsicColumn(rows, spacing=0.0f0, padding=0.0f0);
        style=ContainerStyle(
            background_color=style.item_background,
            border_color=style.border_color,
            border_width=style.border_width,
            padding=style.padding,
            corner_radius=style.corner_radius,
        ),
    )
end

# Build a single row view.
function _multiselect_row(
    label::String,
    i::Int,
    state_ref::Ref{MultiSelectState},
    style::MultiSelectListStyle,
    emit::Function,
    on_change::Function,
)::AbstractView
    # Read visual state once at view-build time (safe — called before detect_click).
    state = state_ref[]
    is_selected = i in state.selected_indices

    active_text_style = (is_selected && style.text_style_selected !== nothing) ?
                        style.text_style_selected : style.text_style

    row_style = ContainerStyle(
        background_color=is_selected ? style.item_selected_color : style.item_background,
        border_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.0f0),
        border_width=0.0f0,
        padding=4.0f0,
        corner_radius=0.0f0,
    )
    row_hover_style = ContainerStyle(
        background_color=is_selected ? style.item_selected_hover_color : style.item_hover_color,
        border_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.0f0),
        border_width=0.0f0,
        padding=4.0f0,
        corner_radius=0.0f0,
    )

    return FixedHeight(
        Container(
            Text(label, style=active_text_style, wrap_text=false),
            style=row_style,
            hover_style=row_hover_style,
            interaction_state=state.row_states[i],
            on_interaction_state_change=(new_row_state) -> begin
                # Read the CURRENT state (may have been updated by an earlier
                # callback in the same frame's detect_click pass).
                s = state_ref[]
                new_row_states = copy(s.row_states)
                new_row_states[i] = new_row_state
                emit(MultiSelectState(s; row_states=new_row_states))
            end,
            on_click=() -> begin
                s = state_ref[]
                new_selected = copy(s.selected_indices)
                if i in new_selected
                    delete!(new_selected, i)
                else
                    push!(new_selected, i)
                end
                emit(MultiSelectState(new_selected, copy(s.row_states)))
                on_change(new_selected)
            end,
        ),
        style.item_height,
    )
end

function _multiselect_resize_states(existing::Vector{InteractionState}, n::Int)::Vector{InteractionState}
    length(existing) == n && return existing
    result = Vector{InteractionState}(undef, n)
    for i in 1:n
        result[i] = i <= length(existing) ? existing[i] : InteractionState()
    end
    return result
end
