# FileExplorer

A minimalistic file and directory browser. It renders a flat, scrollable list of the
entries in `current_dir`, with expandable sub-directories. Interaction is purely
click-based:

## Basic Usage

```@example FileExplorerBasic
using Fugl

fe_state = Ref(FileExplorerState(homedir()))

function MyApp()
    FileExplorer(
        fe_state[];
        on_state_change=(ns) -> fe_state[] = ns,
        on_open=(abs_path, name, is_dir) -> println("Opened: $abs_path"),
    )
end

screenshot(MyApp, "file_explorer_basic.png", 400, 300);
nothing #hide
```

![FileExplorer basic](file_explorer_basic.png)

## Inside a Scroll Area

Wrap the explorer in a `VerticalScrollArea` so that large directories can be scrolled.

```@example FileExplorerScroll
using Fugl

fe_state     = Ref(FileExplorerState(homedir()))
scroll_state = Ref(VerticalScrollState())

function MyApp()
    VerticalScrollArea(
        FileExplorer(
            fe_state[];
            on_state_change=(ns) -> fe_state[] = ns,
        );
        scroll_state=scroll_state[],
        on_scroll_change=(ns) -> scroll_state[] = ns,
    )
end

screenshot(MyApp, "file_explorer_scroll.png", 400, 300);
nothing #hide
```

![FileExplorer in scroll area](file_explorer_scroll.png)

## Custom Icons

`dir_icon` and `file_icon` set the default glyphs; `extension_icons` overrides the
file icon per extension. All icons are single `Char` values — only monochrome glyphs
from the loaded font are supported (no emoji).

```@example FileExplorerIcons
using Fugl

fe_state     = Ref(FileExplorerState(homedir()))
scroll_state = Ref(VerticalScrollState())

function MyApp()
    VerticalScrollArea(
        FileExplorer(
            fe_state[];
            dir_icon  = '▸',
            file_icon = '·',
            extension_icons = Dict{String,Char}(
                ".jl"   => '◆',
                ".md"   => '§',
                ".toml" => '≡',
                ".txt"  => '≡',
            ),
            on_state_change=(ns) -> fe_state[] = ns,
        );
        scroll_state=scroll_state[],
        on_scroll_change=(ns) -> scroll_state[] = ns,
    )
end

screenshot(MyApp, "file_explorer_icons.png", 400, 300);
nothing #hide
```

![FileExplorer with custom icons](file_explorer_icons.png)

## Style Customisation

Use `FileExplorerStyle` to control colours, row height, and indent width.

```@example FileExplorerStyle
using Fugl

fe_state     = Ref(FileExplorerState(homedir()))
scroll_state = Ref(VerticalScrollState())

custom_style = FileExplorerStyle(
    row_height       = 26.0f0,
    indent           = 20.0f0,
    background_color = Vec4f(0.08, 0.08, 0.10, 1.0),
    normal_style     = TextStyle(size_points=13, color=Vec4f(0.75, 0.75, 0.75, 1.0)),
    selected_style   = TextStyle(size_points=13, color=Vec4f(1.0,  1.0,  1.0,  1.0)),
    dir_color        = Vec4f(0.55, 0.78, 1.0, 1.0),
    selected_bg      = Vec4f(0.18, 0.34, 0.60, 1.0),
    hover_bg         = Vec4f(0.20, 0.20, 0.22, 1.0),
)

function MyApp()
    VerticalScrollArea(
        FileExplorer(
            fe_state[];
            style=custom_style,
            on_state_change=(ns) -> fe_state[] = ns,
        );
        scroll_state=scroll_state[],
        on_scroll_change=(ns) -> scroll_state[] = ns,
    )
end

screenshot(MyApp, "file_explorer_style.png", 400, 300);
nothing #hide
```

![FileExplorer styled](file_explorer_style.png)
