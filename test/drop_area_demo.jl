using Fugl
using Fugl: Text

# --- Styles (defined once outside the render function) ---

const BG_COLOR = Vec4f(0.08, 0.08, 0.10, 1.0)
const SURFACE_COLOR = Vec4f(0.14, 0.14, 0.18, 1.0)
const BORDER_COLOR = Vec4f(0.28, 0.28, 0.32, 1.0)
const ACCENT_COLOR = Vec4f(0.25, 0.55, 0.90, 1.0)
const TEXT_COLOR = Vec4f(0.90, 0.90, 0.92, 1.0)
const MUTED_COLOR = Vec4f(0.55, 0.55, 0.60, 1.0)

const drop_zone_style = ContainerStyle(
    background_color=SURFACE_COLOR,
    border_color=BORDER_COLOR,
    border_width=2.0f0,
    padding=24.0f0,
    corner_radius=10.0f0
)

const drop_zone_active_style = ContainerStyle(
    background_color=Vec4f(0.12, 0.22, 0.38, 1.0),
    border_color=ACCENT_COLOR,
    border_width=2.5f0,
    padding=24.0f0,
    corner_radius=10.0f0
)

const file_item_style = ContainerStyle(
    background_color=Vec4f(0.10, 0.10, 0.14, 1.0),
    border_color=Vec4f(0.22, 0.22, 0.26, 1.0),
    border_width=1.0f0,
    padding=8.0f0,
    corner_radius=5.0f0
)

const title_style = TextStyle(color=TEXT_COLOR, size_points=18)
const label_style = TextStyle(color=TEXT_COLOR, size_points=14)
const hint_style = TextStyle(color=MUTED_COLOR, size_points=12)
const path_style = TextStyle(color=TEXT_COLOR, size_points=12)
const accent_style = TextStyle(color=ACCENT_COLOR, size_points=14)

dropped_paths = Ref(String[])

function DropAreaDemo()
    has_files = !isempty(dropped_paths[])

    # Drop zone content
    zone_content = if has_files
        Column(
            Text("Files received", style=accent_style),
            Text("$(length(dropped_paths[])) file(s) dropped", style=hint_style)
        )
    else
        Column(
            Text("Drop files here", style=label_style),
            Text("Drag one or more files from your file manager onto this area", style=hint_style)
        )
    end

    zone_style = has_files ? drop_zone_active_style : drop_zone_style

    drop_zone = DropArea(
        Container(zone_content; style=zone_style)) do paths
        dropped_paths[] = copy(paths)
    end

    # File list
    file_list = if has_files
        items = [
            Container(
                Text(p; style=path_style);
                style=file_item_style
            )
            for p in dropped_paths[]
        ]
        Column(items...)
    else
        Empty()
    end

    Card("DropArea Demo",
        Column(
            FixedHeight(drop_zone, 120.0f0),
            file_list
        );
        style=ContainerStyle(
            background_color=BG_COLOR,
            padding=32.0f0
        ),
        title_style=title_style
    )
end

Fugl.run(DropAreaDemo; title="DropArea Demo", window_width_points=700, window_height_points=500)
