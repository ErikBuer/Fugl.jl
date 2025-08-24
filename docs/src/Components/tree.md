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
