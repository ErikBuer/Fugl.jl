# Tree

A tree componnent, primarily intended to show file structure/select files.

```@example TreeExample
using Fugl

function MyApp()
    project_dir = pwd()
    items = [item for item in walkdir(project_dir)]
    root_node = tree_from_walkdir(items)
    tree_state = Ref(TreeState(root_node; open_folders=Set([root_node.name])))

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
