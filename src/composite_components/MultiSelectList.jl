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
    item_corner_radius::Float32  # Corner radius for selected item highlighting
    max_visible_items::Int  # Maximum items to show before scrolling
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
    item_corner_radius::Float32=4.0f0,
    max_visible_items::Int=10,
)
    return MultiSelectListStyle(
        item_height, text_style, text_style_selected,
        item_background, item_hover_color,
        item_selected_color, item_selected_hover_color,
        border_color, border_width, padding, corner_radius,
        item_corner_radius, max_visible_items,
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
    scroll_offset::Int  # 0-based scroll offset for visible window
end

function MultiSelectState(n_items::Int; selected_indices::Set{Int}=Set{Int}(), scroll_offset::Int=0)
    return MultiSelectState(selected_indices, [InteractionState() for _ in 1:n_items], scroll_offset)
end

function MultiSelectState(base::MultiSelectState;
    selected_indices=base.selected_indices,
    row_states=base.row_states,
    scroll_offset=base.scroll_offset,
)
    return MultiSelectState(selected_indices, row_states, scroll_offset)
end

"""
    MultiSelectList(
        options::Vector{String},
        state::MultiSelectState;
        style::MultiSelectListStyle = MultiSelectListStyle(),
        on_state_change::Function = (new_state) -> nothing,
        on_change::Function = (selected_indices::Set{Int}) -> nothing,
    )

A form component displaying a scrollable list of items where multiple rows can be selected
by clicking. Selected rows are highlighted and deselect-able by clicking again.

The component is flexible in height and shows a maximum of `style.max_visible_items`
rows at once, with scroll support for longer lists.

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
struct MultiSelectListView <: AbstractView
    options::Vector{String}
    state::MultiSelectState
    style::MultiSelectListStyle
    on_state_change::Function
    on_change::Function
end

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

    return MultiSelectListView(options, initial_state, style, on_state_change, on_change)
end

# DEPRECATED measure function
function measure(view::MultiSelectListView)::Tuple{Float32,Float32}
    # Flexible width, height based on visible items
    visible_items = min(length(view.options), view.style.max_visible_items)
    height = visible_items * view.style.item_height + 2 * view.style.padding
    return (Inf32, height)
end

function measure_height(view::MultiSelectListView, available_width::Float32)::Float32
    visible_items = min(length(view.options), view.style.max_visible_items)
    return visible_items * view.style.item_height + 2 * view.style.padding
end

function measure_width(view::MultiSelectListView, available_height::Float32)::Float32
    return Inf32
end

function preferred_height(view::MultiSelectListView)::Bool
    return false  # Flexible component
end

function preferred_width(view::MultiSelectListView)::Bool
    return false  # Flexible component
end

function interpret_view(view::MultiSelectListView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Draw container background
    draw_rounded_rectangle(
        [Point2f(x, y + height),
            Point2f(x, y),
            Point2f(x + width, y),
            Point2f(x + width, y + height)],
        width, height,
        view.style.item_background,
        view.style.border_color,
        view.style.border_width,
        view.style.corner_radius,
        projection_matrix,
        1.0f0
    )

    # Calculate visible items based on both max_visible_items and available height
    total_items = length(view.options)
    available_item_height = height - 2 * view.style.padding
    max_items_that_fit = Int(floor(available_item_height / view.style.item_height))
    visible_items = min(total_items, view.style.max_visible_items, max(1, max_items_that_fit))

    # Calculate item slice to render
    start_idx = view.state.scroll_offset + 1
    end_idx = min(total_items, start_idx + visible_items - 1)

    # Helper function to determine corner rounding for selected items
    function get_corner_radii(item_idx::Int)::Vec4{Float32}
        radius = view.style.item_corner_radius

        # Check if this item is selected
        if !(item_idx in view.state.selected_indices)
            return Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.0f0)
        end

        # Check adjacent items in the FULL selection (not just visible)
        prev_selected = (item_idx - 1) in view.state.selected_indices
        next_selected = (item_idx + 1) in view.state.selected_indices

        if !prev_selected && !next_selected
            # Single selected item - round all corners
            return Vec4{Float32}(radius, radius, radius, radius)
        elseif !prev_selected && next_selected
            # Top of group - round top corners only
            # Vec4 order: top-left, top-right, bottom-right, bottom-left
            return Vec4{Float32}(radius, radius, 0.0f0, 0.0f0)
        elseif prev_selected && !next_selected
            # Bottom of group - round bottom corners only
            # Vec4 order: top-left, top-right, bottom-right, bottom-left
            return Vec4{Float32}(0.0f0, 0.0f0, radius, radius)
        else
            # Middle of a group - no rounding
            return Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.0f0)
        end
    end

    # Render visible items from top to bottom
    for i in start_idx:end_idx
        visible_row_idx = i - start_idx + 1
        item_x = x + view.style.padding
        item_width = width - 2 * view.style.padding

        # Position this item, starting from top and moving down (true top-down layout)
        current_item_y = y + view.style.padding + ((visible_row_idx - 1) * view.style.item_height)

        is_selected = i in view.state.selected_indices
        row_state = i <= length(view.state.row_states) ? view.state.row_states[i] : InteractionState()

        # Determine background color based on selection and hover state
        bg_color = if is_selected
            row_state.is_hovered ? view.style.item_selected_hover_color : view.style.item_selected_color
        else
            row_state.is_hovered ? view.style.item_hover_color : view.style.item_background
        end

        # Draw item background with smart corner rounding
        # Add small overlap for selected items to ensure they connect properly
        item_height_adjusted = is_selected ? view.style.item_height + 1.0f0 : view.style.item_height
        item_y_adjusted = is_selected && i > 1 && (i - 1) in view.state.selected_indices ?
                          current_item_y - 0.5f0 : current_item_y

        # Use generate_rectangle_vertices for correct UV/corner mapping
        vertices = generate_rectangle_vertices(item_x, item_y_adjusted, item_width, item_height_adjusted)

        if (is_selected || row_state.is_hovered) && view.style.item_corner_radius > 0.0f0
            # Use configurable rectangle for selected/hovered items with smart rounding
            corner_radii = is_selected ? get_corner_radii(i) : Vec4{Float32}(view.style.item_corner_radius, view.style.item_corner_radius, view.style.item_corner_radius, view.style.item_corner_radius)
            draw_configurable_rectangle(
                vertices, item_width, item_height_adjusted,
                bg_color, bg_color,  # Same color for border and fill
                0.0f0, corner_radii, # No border, just corner rounding
                projection_matrix, 1.0f0
            )
        else
            # Use regular rectangle for non-selected, non-hovered items
            draw_rectangle(vertices, bg_color, projection_matrix)
        end

        # Draw text
        active_text_style = (is_selected && view.style.text_style_selected !== nothing) ?
                            view.style.text_style_selected : view.style.text_style

        text_x = item_x + 8.0f0  # Left padding
        text_y = Float32(current_item_y + view.style.item_height / 2 + Float32(active_text_style.size_points) / 3)  # Vertically center

        label_font = get_font(active_text_style)
        draw_text(
            label_font,
            view.options[i],
            text_x,
            text_y,
            Int(active_text_style.size_points),
            projection_matrix,
            active_text_style.color;
            clip_bounds_points=Rectangle(x, y, width, height)
        )
    end
end

function detect_click(view::MultiSelectListView, input_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    z = parent_z + 1
    mouse_x, mouse_y = input_state.x, input_state.y

    # Check if mouse is within component bounds
    if !(mouse_x >= x && mouse_x <= x + width && mouse_y >= y && mouse_y <= y + height)
        return nothing
    end

    # Handle scroll wheel events
    if input_state.scroll_y != 0.0
        total_items = length(view.options)
        available_item_height = height - 2 * view.style.padding
        max_items_that_fit = Int(floor(available_item_height / view.style.item_height))
        visible_items = min(total_items, view.style.max_visible_items, max(1, max_items_that_fit))
        max_scroll = max(0, total_items - visible_items)

        new_scroll_offset = if input_state.scroll_y > 0.0
            # Scroll up (show earlier items)
            max(0, view.state.scroll_offset - 1)
        else
            # Scroll down (show later items)
            min(max_scroll, view.state.scroll_offset + 1)
        end

        if new_scroll_offset != view.state.scroll_offset
            new_state = MultiSelectState(view.state; scroll_offset=new_scroll_offset)
            return ClickResult(z, () -> view.on_state_change(new_state))
        end
    end

    # Calculate which item the mouse is over
    total_items = length(view.options)
    available_item_height = height - 2 * view.style.padding
    max_items_that_fit = Int(floor(available_item_height / view.style.item_height))
    visible_items = min(total_items, view.style.max_visible_items, max(1, max_items_that_fit))
    start_idx = view.state.scroll_offset + 1
    end_idx = min(total_items, start_idx + visible_items - 1)

    # Calculate item position based on top-down layout
    relative_y = mouse_y - (y + view.style.padding)
    if relative_y >= 0 && relative_y <= (visible_items * view.style.item_height)
        item_index = Int(floor(relative_y / view.style.item_height)) + 1
        actual_index = start_idx + item_index - 1

        if actual_index >= start_idx && actual_index <= end_idx
            current_state = view.state

            # Handle hover state changes
            if actual_index <= length(current_state.row_states)
                current_row_state = current_state.row_states[actual_index]
                if !current_row_state.is_hovered
                    new_row_states = copy(current_state.row_states)
                    # Clear other hovers
                    for i in 1:length(new_row_states)
                        if i != actual_index && new_row_states[i].is_hovered
                            new_row_states[i] = InteractionState(new_row_states[i]; is_hovered=false)
                        end
                    end
                    new_row_states[actual_index] = InteractionState(current_row_state; is_hovered=true)
                    new_state = MultiSelectState(current_state; row_states=new_row_states)
                    view.on_state_change(new_state)
                end
            end

            # Handle click
            if input_state.mouse_down[LeftButton]
                new_selected = copy(current_state.selected_indices)
                if actual_index in new_selected
                    delete!(new_selected, actual_index)
                else
                    push!(new_selected, actual_index)
                end
                new_state = MultiSelectState(current_state; selected_indices=new_selected)
                return ClickResult(z, () -> begin
                    view.on_state_change(new_state)
                    view.on_change(new_selected)
                end)
            end
        end
    else
        # Mouse not over any item - clear hover states
        current_state = view.state
        any_hovered = any(rs.is_hovered for rs in current_state.row_states)
        if any_hovered
            new_row_states = [InteractionState(rs; is_hovered=false) for rs in current_state.row_states]
            new_state = MultiSelectState(current_state; row_states=new_row_states)
            view.on_state_change(new_state)
        end
    end

    return nothing
end

# Resize row states vector to match number of options
function _multiselect_resize_states(existing::Vector{InteractionState}, n::Int)::Vector{InteractionState}
    length(existing) == n && return existing
    result = Vector{InteractionState}(undef, n)
    for i in 1:n
        result[i] = i <= length(existing) ? existing[i] : InteractionState()
    end
    return result
end
