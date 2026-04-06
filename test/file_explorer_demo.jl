using Fugl

# Start in the user's home directory
fe_state = Ref(FileExplorerState(homedir()))
modal_open = Ref(false)
status_msg = Ref("No file selected.")
scroll_state = Ref(VerticalScrollState())

open_btn_state = Ref(InteractionState())
up_btn_state = Ref(InteractionState())
open_btn2_state = Ref(InteractionState())
cancel_btn_state = Ref(InteractionState())

const up_btn_style = ContainerStyle(
    background_color=Vec4(0.0f0, 0.0f0, 0.0f0, 0.0f0),
    border_color=Vec4(0.0f0, 0.0f0, 0.0f0, 0.0f0),
    padding=4.0f0,
)
const up_btn_hover_style = ContainerStyle(
    background_color=Vec4(0.0f0, 0.0f0, 0.0f0, 0.0f0),
    border_color=Vec4(0.45f0, 0.45f0, 0.45f0, 1.0f0),
    border_width=1.0f0,
    padding=4.0f0,
)
const up_btn_pressed_style = ContainerStyle(
    background_color=Vec4(0.0f0, 0.0f0, 0.0f0, 0.0f0),
    border_color=Vec4(0.30f0, 0.55f0, 1.0f0, 1.0f0),
    border_width=1.0f0,
    padding=4.0f0,
)
const text_style = TextStyle(size_points=14, color=Vec4(0.9f0, 0.9f0, 0.9f0, 1.0f0))
const status_text_style = TextStyle(size_points=13, color=Vec4(0.7f0, 0.9f0, 0.7f0, 1.0f0))
const path_text_style = TextStyle(size_points=12, color=Vec4(0.65f0, 0.82f0, 1.0f0, 1.0f0))
const title_text_style = TextStyle(size_points=20, color=Vec4(1.0f0, 1.0f0, 1.0f0, 1.0f0))

const path_box_style = ContainerStyle(
    background_color=Vec4(0.0f0, 0.0f0, 0.0f0, 0.0f0),
    border_color=Vec4(0.35f0, 0.35f0, 0.35f0, 1.0f0),
    border_width=1.0f0,
    padding=4.0f0,
)
const breadcrumb_style = ContainerStyle(
    background_color=Vec4(0.10f0, 0.10f0, 0.10f0, 1.0f0),
    padding=4.0f0,
)
const explorer_style = ContainerStyle(
    background_color=Vec4(0.12f0, 0.12f0, 0.12f0, 1.0f0),
    border_color=Vec4(0.25f0, 0.25f0, 0.25f0, 1.0f0),
    border_width=1.0f0,
    corner_radius=6.0f0,
)
const modal_content_style = ContainerStyle(
    background_color=Vec4(0.14f0, 0.14f0, 0.14f0, 1.0f0),
    border_color=Vec4(0.30f0, 0.30f0, 0.30f0, 1.0f0),
    corner_radius=6.0f0,
)
const background_style = ContainerStyle(
    background_color=Vec4(0.12f0, 0.12f0, 0.12f0, 1.0f0),
)

const modal_btn_style = ContainerStyle(
    background_color=Vec4(0.0f0, 0.0f0, 0.0f0, 0.0f0),
    border_color=Vec4(0.35f0, 0.35f0, 0.35f0, 1.0f0),
    border_width=1.0f0,
    padding=4.0f0,
)

const dark_scrollbar_style = ScrollAreaStyle(
    scrollbar_width=12.0f0,
    scrollbar_color=Vec4f(0.35, 0.35, 0.35, 1.0),
    scrollbar_background_color=Vec4f(0.18, 0.18, 0.18, 1.0),
    scrollbar_hover_color=Vec4f(0.50, 0.50, 0.50, 1.0),
    corner_color=Vec4f(0.18, 0.18, 0.18, 1.0),
    corner_radius=4.0f0
)

function FileExplorerDemo()
    open_btn = TextButton("Open File Explorer";
        on_click=() -> modal_open[] = true,
        interaction_state=open_btn_state[],
        on_interaction_state_change=(new_state) -> open_btn_state[] = new_state,
    )

    status = Fugl.Text(status_msg[];
        style=status_text_style,
        horizontal_align=:left,
    )

    # Breadcrumb: show the current directory
    breadcrumb = BaseContainer(
        IntrinsicHeight(
            IntrinsicRow(
                FixedWidth(
                    TextButton("↑";
                        on_click=() -> begin
                            parent = dirname(fe_state[].current_dir)
                            if parent != fe_state[].current_dir
                                fe_state[] = FileExplorerState(parent)
                            end
                        end,
                        container_style=up_btn_style,
                        text_style=text_style,
                        hover_style=up_btn_hover_style,
                        pressed_style=up_btn_pressed_style,
                        interaction_state=up_btn_state[],
                        on_interaction_state_change=(new_state) -> up_btn_state[] = new_state,
                    ),
                    32.0f0
                ),
                FlexibleWidth(
                    BaseContainer(
                        Fugl.Text(fe_state[].current_dir;   # TODO make input field to allow direct path entry
                            style=path_text_style,
                            horizontal_align=:left,
                            wrap_text=false,
                        );
                        style=path_box_style
                    )
                ),
            )
        );
        style=breadcrumb_style
    )

    explorer = BaseContainer(
        VerticalScrollArea(
            FileExplorer(
                fe_state[];
                dir_icon='',
                file_icon='',
                extension_icons=Dict{String,Char}(
                    ".jl" => '',
                    ".md" => '',
                    ".rs" => '',
                    ".py" => '',
                    ".c" => '',
                    ".cpp" => '',
                    ".js" => '',
                    ".xml" => '',
                ),
                on_state_change=(ns) -> fe_state[] = ns,
                on_select=(abs_path, name, is_dir) -> begin
                    label = is_dir ? "$name" : "$name"
                    status_msg[] = "Selected: $label"
                end,
                on_open=(abs_path, name, is_dir) -> begin
                    if !is_dir
                        status_msg[] = "Open: $abs_path"
                        modal_open[] = false
                    end
                end,
            );
            style=dark_scrollbar_style,
            scroll_state=scroll_state[],
            on_scroll_change=(ns) -> scroll_state[] = ns,
        ),
        style=explorer_style,
    )

    modal_content = BaseContainer(
        IntrinsicColumn(
            breadcrumb,
            explorer,
            IntrinsicHeight(
                Row(
                    FixedHeight(
                        TextButton("Open";
                            on_click=() -> begin
                                sel = fe_state[].selected
                                if sel !== nothing
                                    abs_path = joinpath(fe_state[].current_dir, sel)
                                    if isdir(abs_path)
                                        # Navigate to folder
                                        fe_state[] = FileExplorerState(abs_path)
                                        status_msg[] = "Navigated to: $abs_path"
                                    else
                                        # Open file and close modal
                                        status_msg[] = "Opened: $abs_path"
                                        modal_open[] = false
                                    end
                                else
                                    modal_open[] = false
                                end
                            end,
                            container_style=modal_btn_style,
                            text_style=text_style,
                            hover_style=up_btn_hover_style,
                            pressed_style=up_btn_pressed_style,
                            interaction_state=open_btn2_state[],
                            on_interaction_state_change=(new_state) -> open_btn2_state[] = new_state,
                        ),
                        32.0f0
                    ),
                    FixedHeight(
                        TextButton("Cancel";
                            on_click=() -> modal_open[] = false,
                            container_style=modal_btn_style,
                            text_style=text_style,
                            hover_style=up_btn_hover_style,
                            pressed_style=up_btn_pressed_style,
                            interaction_state=cancel_btn_state[],
                            on_interaction_state_change=(new_state) -> cancel_btn_state[] = new_state,
                        ),
                        32.0f0
                    ),
                    padding=4.0f0, spacing=10.0f0),
            ),
        );
        style=modal_content_style
    )

    background = BaseContainer(
        IntrinsicColumn(
            Fugl.Text("File Explorer Demo";
                style=title_text_style,
            ),
            Padding(open_btn, 8.0f0),
            Padding(status, 8.0f0),
        );
        style=background_style
    )

    if modal_open[]
        Modal(
            background,
            modal_content;
            child_width=480.0f0,
            child_height=440.0f0,
            on_click_outside=() -> modal_open[] = false,
        )
    else
        background
    end
end

Fugl.run(FileExplorerDemo; title="File Explorer Demo", window_width_points=720, window_height_points=520)
