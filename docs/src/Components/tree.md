# Tree

A tree componnent, primarily intended to show file structure/select files.

```@example TreeExample
using Fugl

function MyApp()
    project_dir = pwd()
    items = [item for item in walkdir(project_dir)]
    root_node = tree_from_walkdir(items)
    tree_state = Ref(TreeState(root_node))

    Card(
        "Explorer",
        Tree(
            tree_state[];
            on_state_change=(new_state) -> tree_state[] = new_state
        )
    )
end

screenshot(MyApp, "tree_example.png", 400, 600);
nothing #hide
```

![Tree Example](tree_example.png)

## Dark Mode Example

```@example TreeDarkExample
using Fugl

function MyApp()
    project_dir = pwd()
    items = [item for item in walkdir(project_dir)]
    root_node = tree_from_walkdir(items)
    tree_state = Ref(TreeState(root_node))

    # Dark theme tree style
    dark_tree_style = TreeStyle(
        selected = TextStyle(
            color = Vec4f(0.3, 0.7, 1.0, 1.0),      # Bright blue for selected items
            size_px = 14
        ),
        normal = TextStyle(
            color = Vec4f(0.85, 0.85, 0.9, 1.0),    # Light gray for normal text
            size_px = 14
        )
    )

    # Dark theme card style
    dark_card_style = ContainerStyle(
        background_color = Vec4f(0.15, 0.15, 0.18, 1.0),  # Dark background
        border_color = Vec4f(0.35, 0.35, 0.4, 1.0),       # Subtle border
        border_width = 1.5f0,
        corner_radius = 8.0f0,
        padding = 12.0f0
    )

    # Dark theme title style
    dark_title_style = TextStyle(
        size_px = 16,
        color = Vec4f(0.9, 0.9, 0.95, 1.0)  # Light title text
    )

    Container(
        Card(
            "Dark Explorer",
            Tree(
                tree_state[];
                style = dark_tree_style,
                on_state_change = (new_state) -> tree_state[] = new_state,
                on_select = (path, name) -> println("Selected: $name at $path")
            ),
            style = dark_card_style,
            title_style = dark_title_style
        ),
        style = ContainerStyle(
            background_color = Vec4f(0.10, 0.10, 0.12, 1.0),  # Even darker outer background
            padding = 15.0f0
        )
    )
end

screenshot(MyApp, "tree_dark_example.png", 450, 600);
nothing #hide
```

![Dark Tree Example](tree_dark_example.png)

## Empty contents

```@example TreeEmptyExample
using Fugl

function MyApp()
    tree_state = Ref(TreeState(nothing))
    Card("Explorer", Tree(tree_state[]))
end

screenshot(MyApp, "tree_empty_example.png", 400, 120);
nothing #hide
```

![Empty Tree Example](tree_empty_example.png)

---

```@example TreeEmptyFolderExample
using Fugl

function MyApp()
    empty_node = TreeNode("EmptyFolder", TreeNode[], true)
    tree_state = Ref(TreeState(empty_node; open_folders=Set([empty_node.name])))
    Card("Explorer", Tree(tree_state[]))
end

screenshot(MyApp, "tree_empty_folder_example.png", 400, 120);
nothing #hide
```

![Empty Folder Example](tree_empty_folder_example.png)
