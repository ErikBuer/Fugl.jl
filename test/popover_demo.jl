using Fugl
using Fugl: Text  # Explicitly import Text to avoid ambiguity

const IMAGE_PATH = joinpath(@__DIR__, "images", "logo.png")

const THUMB_SIZE = 64.0f0
const ZOOM_SIZE = THUMB_SIZE * 4  # Popover shows the image at 4x the thumbnail size

popover_state = Ref(PopoverState())

thumbnail_style = ContainerStyle(
    border_color=Vec4f(0.3, 0.3, 0.3, 1.0),
    border_width=1.5f0,
    padding=4.0f0,
    corner_radius=4.0f0
)

zoom_popover_style = PopoverStyle(
    padding=8.0f0,
    corner_radius=8.0f0
)

function popover_demo()
    Container(
        IntrinsicColumn([
                Container(
                    Text("Popover Demo - Hover to Zoom", style=TextStyle(size_points=24.0f0)),
                    style=ContainerStyle(padding=20.0f0)
                ),
                Container(
                    Popover(
                        Container(
                            FixedSize(Image(IMAGE_PATH), THUMB_SIZE, THUMB_SIZE),
                            style=thumbnail_style
                        ),
                        FixedSize(Image(IMAGE_PATH), ZOOM_SIZE, ZOOM_SIZE);
                        popover_width=ZOOM_SIZE + 2 * zoom_popover_style.padding,
                        popover_height=ZOOM_SIZE + 2 * zoom_popover_style.padding,
                        position=:right,
                        style=zoom_popover_style,
                        state=popover_state[],
                        on_state_change=(new_state) -> popover_state[] = new_state
                    ),
                    style=ContainerStyle(padding=20.0f0)
                ),
                Container(
                    Text(
                        "Instructions:\\n• Hover over the thumbnail to see a 4x preview\\n• Move the mouse away to hide it",
                        style=TextStyle(size_points=14.0f0)
                    ),
                    style=ContainerStyle(
                        background_color=Vec4f(0.95, 0.95, 0.95, 1.0),
                        padding=15.0f0,
                        corner_radius=5.0f0
                    )
                )
            ], spacing=10.0f0),
        style=ContainerStyle(
            background_color=Vec4f(0.98, 0.98, 1.0, 1.0),
            padding=30.0f0
        )
    )
end

Fugl.run(popover_demo, title="Popover Demo", window_width_points=900, window_height_points=700)
