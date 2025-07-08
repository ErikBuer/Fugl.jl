# Container

The most basic UI component.

``` @example ContainerExample
using Fugl

function MyApp()
    Container()
end

screenshot(MyApp, "container.png", 400, 300);
nothing #hide
```

![Container](container.png)

You can add a child component to a cointainer, as such:

``` @example ContainerExample2
using Fugl

function MyApp()
    Container(
        Container()
    )
end

screenshot(MyApp, "container_child.png", 400, 300);
nothing #hide
```

![Container](container_child.png)
