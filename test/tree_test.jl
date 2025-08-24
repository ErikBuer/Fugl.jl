using Fugl

project_dir = pwd()
items = [item for item in walkdir(project_dir)]
root_node = tree_from_walkdir(items)
tree_state = Ref(TreeState(root_node))
#tree_state = Ref(TreeState(nothing))

function my_gui()
    Card(
        "Explorer",
        Tree(
            tree_state[];
            on_state_change=(new_state) -> tree_state[] = new_state,
            on_select=(path, name) -> println("Selected: $path - $name")
        )
    )
end

# Run the simple test
Fugl.run(my_gui, title="Tree", window_width_px=300, window_height_px=800, fps_overlay=true)
