include("file_explorer_state.jl")
include("file_explorer_style.jl")

"""
    FileExplorerView

A minimalistic file/folder browser.
"""
struct FileExplorerView <: AbstractView
    state::FileExplorerState
    style::FileExplorerStyle
    extension_icons::Dict{String,Char}  # e.g. Dict(".jl" => '◆', ".md" => '§')
    dir_icon::Char                      # Monochrome glyph between the arrow and a directory name
    file_icon::Char                     # Fallback glyph before a file name
    on_state_change::Function   # (new_state::FileExplorerState) -> nothing
    on_select::Function         # (abs_path::String, name::String, is_dir::Bool) -> nothing
    on_open::Function           # (abs_path::String, name::String, is_dir::Bool) -> nothing
end

"""
    FileExplorer(state; style, on_state_change, on_select, on_open)

Create a file explorer component rooted at `state.current_dir`.
"""
function FileExplorer(
    state::FileExplorerState;
    style::FileExplorerStyle=FileExplorerStyle(),
    extension_icons::Dict{String,Char}=Dict{String,Char}(),
    dir_icon::Char='',
    file_icon::Char='',
    on_state_change::Function=(ns) -> nothing,
    on_select::Function=(abs_path, name, is_dir) -> nothing,
    on_open::Function=(abs_path, name, is_dir) -> nothing,
)
    return FileExplorerView(state, style, extension_icons, dir_icon, file_icon, on_state_change, on_select, on_open)
end

function measure(view::FileExplorerView)::Tuple{Float32,Float32}
    entries = _fe_visible_entries(view.state)
    h = Float32(length(entries)) * view.style.row_height
    return (Inf32, h)
end

function measure_height(view::FileExplorerView, available_width::Float32)::Float32
    entries = _fe_visible_entries(view.state)
    return Float32(length(entries)) * view.style.row_height
end

function measure_width(view::FileExplorerView, available_height::Float32)::Float32
    return Inf32
end

function apply_layout(view::FileExplorerView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

"""
Flat list of visible entries as `(abs_path, rel_path, name, is_dir, depth)`.
Directories come before files at each level; both groups are sorted by name.
"""
function _fe_visible_entries(
    state::FileExplorerState,
)::Vector{Tuple{String,String,String,Bool,Int}}
    entries = Tuple{String,String,String,Bool,Int}[]
    function scan(abs_dir::String, rel_dir::String, depth::Int)
        names = try
            readdir(abs_dir)
        catch
            return
        end
        dirs = sort(filter(n -> isdir(joinpath(abs_dir, n)), names))
        files = sort(filter(n -> !isdir(joinpath(abs_dir, n)), names))
        for name in vcat(dirs, files)
            abs_path = joinpath(abs_dir, name)
            rel_path = rel_dir == "" ? name : joinpath(rel_dir, name)
            is_dir = name ∈ dirs
            push!(entries, (abs_path, rel_path, name, is_dir, depth))
            if is_dir && rel_path ∈ state.open_dirs
                scan(abs_path, rel_path, depth + 1)
            end
        end
    end
    isdir(state.current_dir) && scan(state.current_dir, "", 0)
    return entries
end

# Arrow glyphs for expand/collapse state (not user-configurable)
const _FE_ARROW_OPEN = "▼ "   # expanded directory
const _FE_ARROW_CLOSED = "▶ "   # collapsed directory

function interpret_view(
    view::FileExplorerView,
    x::Float32, y::Float32, width::Float32, height::Float32,
    projection_matrix::Mat4{Float32},
    cursor_position::Point2f,
)
    # Background
    bg_verts = generate_rectangle_vertices(x, y, width, height)
    draw_rectangle(bg_verts, view.style.background_color, projection_matrix)

    entries = _fe_visible_entries(view.state)
    row_h = view.style.row_height
    indent = view.style.indent

    for (idx, (abs_path, rel_path, name, is_dir, depth)) in enumerate(entries)
        row_y = y + (idx - 1) * row_h
        row_y + row_h < y && continue   # above viewport  (scroll parent handles this)
        row_y > y + height && break     # below viewport

        row_x = x + depth * indent

        is_selected = rel_path == view.state.selected
        is_hovered = cursor_position[1] >= x && cursor_position[1] < x + width &&
                     cursor_position[2] >= row_y && cursor_position[2] < row_y + row_h

        # Row background: selected > hover > transparent
        if is_selected
            sel_verts = generate_rectangle_vertices(x, row_y, width, row_h)
            draw_rectangle(sel_verts, view.style.selected_bg, projection_matrix)
        elseif is_hovered
            hov_verts = generate_rectangle_vertices(x, row_y, width, row_h)
            draw_rectangle(hov_verts, view.style.hover_bg, projection_matrix)
        end

        # Build label: arrow (dirs only) + icon + space + name
        if is_dir
            is_open = rel_path ∈ view.state.open_dirs
            arrow_str = is_open ? _FE_ARROW_OPEN : _FE_ARROW_CLOSED
            label = arrow_str * view.dir_icon * ' ' * name
        else
            ext = lowercase(splitext(name)[2])   # e.g. ".jl"
            icon = get(view.extension_icons, ext, view.file_icon)
            label = "  " * icon * ' ' * name
        end

        ts = is_selected ? view.style.selected_style : view.style.normal_style
        # Tint directories with dir_color
        if is_dir && !is_selected
            ts = TextStyle(ts; color=view.style.dir_color)
        end

        text_view = Fugl.Text(label; style=ts, horizontal_align=:left, wrap_text=false)
        text_y = row_y + (row_h - Float32(ts.size_points)) / 2.0f0
        interpret_view(text_view, row_x, text_y, width - depth * indent, row_h, projection_matrix, cursor_position)
    end
end

function detect_click(
    view::FileExplorerView,
    mouse_state::InputState,
    x::Float32, y::Float32, width::Float32, height::Float32,
    parent_z::Int32,
)::Union{ClickResult,Nothing}
    is_click = mouse_state.was_clicked[LeftButton]
    is_double_click = mouse_state.was_double_clicked[LeftButton]
    (is_click || is_double_click) || return nothing

    entries = _fe_visible_entries(view.state)
    row_h = view.style.row_height
    z = Int32(parent_z + 1)

    for (idx, (abs_path, rel_path, name, is_dir, depth)) in enumerate(entries)
        row_y = y + (idx - 1) * row_h
        if mouse_state.x >= x && mouse_state.x < x + width &&
           mouse_state.y >= row_y && mouse_state.y < row_y + row_h

            if is_double_click
                # Double click: navigate into dir or open file
                if is_dir
                    action = () -> begin
                        new_state = FileExplorerState(view.state;
                            current_dir=abs_path,
                            open_dirs=Set{String}(),
                            selected=nothing,
                        )
                        view.on_state_change(new_state)
                        view.on_open(abs_path, name, true)
                    end
                else
                    action = () -> begin
                        new_state = FileExplorerState(view.state; selected=rel_path)
                        view.on_state_change(new_state)
                        view.on_open(abs_path, name, false)
                    end
                end
                return ClickResult(z, action)
            else
                # Single click
                if is_dir
                    action = () -> begin
                        new_open = copy(view.state.open_dirs)
                        if rel_path ∈ new_open
                            # Collapse: also remove all children from open set
                            filter!(p -> !startswith(p, rel_path * Base.Filesystem.path_separator) && p != rel_path, new_open)
                        else
                            push!(new_open, rel_path)
                        end
                        new_state = FileExplorerState(view.state;
                            open_dirs=new_open,
                            selected=rel_path,
                        )
                        view.on_state_change(new_state)
                        view.on_select(abs_path, name, true)
                    end
                else
                    action = () -> begin
                        new_state = FileExplorerState(view.state; selected=rel_path)
                        view.on_state_change(new_state)
                        view.on_select(abs_path, name, false)
                    end
                end
                return ClickResult(z, action)
            end
        end
    end

    return nothing
end
