struct MarkdownStyle
    normal::TextStyle
    heading::TextStyle
    subheading::TextStyle
    line_spacing::Float32
    indent_size::Float32   # pixels of x-indent per indent level
end

function MarkdownStyle(
    ;
    normal=TextStyle(),
    heading=TextStyle(normal; size_points=round(Int, normal.size_points * 1.6)),
    subheading=TextStyle(normal; size_points=round(Int, normal.size_points * 1.3)),
    line_spacing=4.0f0,
    indent_size=16.0f0
)
    return MarkdownStyle(normal, heading, subheading, line_spacing, indent_size)
end

# Bullet glyphs for five indent levels (0-based)
const _BULLET_GLYPHS = ("•", "◦", "▪", "▫", "‧")

struct MarkdownLine
    text::String
    style::TextStyle
    indent_level::Int  # 0 = no indent
end

struct MarkdownView <: AbstractView
    text::String
    style::MarkdownStyle
    horizontal_align::Symbol
    wrap_text::Bool
end

function Markdown(
    text::String;
    style=MarkdownStyle(),
    horizontal_align=:left,
    wrap_text=true
)
    return MarkdownView(text, style, horizontal_align, wrap_text)
end

@inline function _to_bold_char(c::Char)::Char
    if c >= 'A' && c <= 'Z'
        return Char(Int(c) - Int('A') + 0x1D400)
    elseif c >= 'a' && c <= 'z'
        return Char(Int(c) - Int('a') + 0x1D41A)
    elseif c >= '0' && c <= '9'
        return Char(Int(c) - Int('0') + 0x1D7CE)
    end
    return c
end

@inline function _to_italic_char(c::Char)::Char
    if c >= 'A' && c <= 'Z'
        return Char(Int(c) - Int('A') + 0x1D434)
    elseif c >= 'a' && c <= 'z'
        # Mathematical italic small h is a special code point.
        return c == 'h' ? Char(0x210E) : Char(Int(c) - Int('a') + 0x1D44E)
    end
    return c
end

@inline function _to_bold_italic_char(c::Char)::Char
    if c >= 'A' && c <= 'Z'
        return Char(Int(c) - Int('A') + 0x1D468)
    elseif c >= 'a' && c <= 'z'
        return Char(Int(c) - Int('a') + 0x1D482)
    end
    return c
end

function _map_text_chars(text::AbstractString, mapper::Function)::String
    io = IOBuffer()
    for c in text
        print(io, mapper(c))
    end
    return String(take!(io))
end

function _apply_inline_markdown(text::AbstractString)::String
    # replace passes the full match string (including delimiters) to the function.
    # Process *** before ** before * so longer markers take priority.
    result = replace(String(text), r"\*\*\*([^*]+)\*\*\*" => m -> _map_text_chars(m[4:end-3], _to_bold_italic_char))
    result = replace(result, r"\*\*([^*]+)\*\*" => m -> _map_text_chars(m[3:end-2], _to_bold_char))
    result = replace(result, r"\*([^*]+)\*" => m -> _map_text_chars(m[2:end-1], _to_italic_char))
    return result
end

function _parse_markdown_lines(view::MarkdownView)::Vector{MarkdownLine}
    parsed = MarkdownLine[]

    for raw_line in split(view.text, '\n')
        stripped = strip(raw_line)

        if startswith(stripped, "# ")
            heading_text = strip(stripped[3:end])
            push!(parsed, MarkdownLine(_map_text_chars(_apply_inline_markdown(heading_text), _to_bold_char), view.style.heading, 0))
            continue
        end

        if startswith(stripped, "## ") || startswith(stripped, "### ")
            marker_len = startswith(stripped, "## ") ? 3 : 4
            subheading_text = strip(stripped[marker_len:end])
            push!(parsed, MarkdownLine(_map_text_chars(_apply_inline_markdown(subheading_text), _to_bold_char), view.style.subheading, 0))
            continue
        end

        # Bullet: detect leading spaces/tabs + "- " for up to 5 indent levels.
        # Each indent level = 2 spaces or 1 tab.
        bullet_match = match(r"^([ \t]*)- (.+)$", raw_line)
        if bullet_match !== nothing
            leading = bullet_match.captures[1]
            # Count indent level: tabs = 1 level each, every 2 spaces = 1 level.
            tab_count = count(c -> c == '\t', leading)
            space_count = count(c -> c == ' ', leading)
            level = clamp(tab_count + div(space_count, 2), 0, 4)
            glyph = _BULLET_GLYPHS[level+1]
            bullet_text = glyph * " " * _apply_inline_markdown(bullet_match.captures[2])
            push!(parsed, MarkdownLine(bullet_text, view.style.normal, level))
            continue
        end

        if isempty(stripped)
            push!(parsed, MarkdownLine("", view.style.normal, 0))
        else
            push!(parsed, MarkdownLine(_apply_inline_markdown(raw_line), view.style.normal, 0))
        end
    end

    return parsed
end

function _line_x_offset(line::MarkdownLine, style::MarkdownStyle)::Float32
    return line.indent_level * style.indent_size
end

function measure(view::MarkdownView)::Tuple{Float32,Float32}
    lines = _parse_markdown_lines(view)
    if isempty(lines)
        return (0.0f0, 0.0f0)
    end

    max_width = 0.0f0
    total_height = 0.0f0
    for line in lines
        x_offset = _line_x_offset(line, view.style)
        text_view = Text(line.text; style=line.style, horizontal_align=view.horizontal_align, vertical_align=:top, wrap_text=false)
        (w, h) = measure(text_view)
        max_width = max(max_width, w + x_offset)
        total_height += h
    end

    total_height += max(0, length(lines) - 1) * view.style.line_spacing
    return (max_width, total_height)
end

function measure_width(view::MarkdownView, available_height::Float32)::Float32
    lines = _parse_markdown_lines(view)
    max_width = 0.0f0
    for line in lines
        x_offset = _line_x_offset(line, view.style)
        text_view = Text(line.text; style=line.style, horizontal_align=view.horizontal_align, vertical_align=:top, wrap_text=false)
        max_width = max(max_width, measure_width(text_view, available_height) + x_offset)
    end
    return max_width
end

function measure_height(view::MarkdownView, available_width::Float32)::Float32
    lines = _parse_markdown_lines(view)
    if isempty(lines)
        return 0.0f0
    end

    total_height = 0.0f0
    for line in lines
        x_offset = _line_x_offset(line, view.style)
        text_view = Text(line.text; style=line.style, horizontal_align=view.horizontal_align, vertical_align=:top, wrap_text=view.wrap_text)
        total_height += measure_height(text_view, max(0.0f0, available_width - x_offset))
    end

    total_height += max(0, length(lines) - 1) * view.style.line_spacing
    return total_height
end

function apply_layout(view::MarkdownView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function interpret_view(view::MarkdownView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f, window_size::Size)
    lines = _parse_markdown_lines(view)
    current_y = y

    for line in lines
        x_offset = _line_x_offset(line, view.style)
        line_x = x + x_offset
        line_width = max(0.0f0, width - x_offset)
        text_view = Text(line.text; style=line.style, horizontal_align=view.horizontal_align, vertical_align=:top, wrap_text=view.wrap_text)
        line_height = measure_height(text_view, line_width)
        interpret_view(text_view, line_x, current_y, line_width, line_height, projection_matrix, cursor_position, window_size)
        current_y += line_height + view.style.line_spacing
    end
end

function preferred_width(::MarkdownView)::Bool
    return true
end

function preferred_height(::MarkdownView)::Bool
    return true
end
