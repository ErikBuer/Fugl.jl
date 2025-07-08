# User interaction

``` @example InteractionExample
using Glance

function MyApp()
    Container( on_click=() -> println("Clicked") )
end
nothing #hide
```

``` @example TextButtonExample
using Glance

function MyApp()
    Container(
        TextButton("Some Text", on_click=() -> println("Clicked"))
    )
end
nothing #hide
```

``` @example HorizontalSliderExample
using Glance

# Ref for maintining the slider state
slider_value = Ref(0.5f0)

function MyApp()
    Container(
        HorizontalSlider(
            slider_value[],
            0.0f0,              # min value
            1.0f0;              # max value
            on_change=(new_value) -> (slider_value[] = new_value)
        )
    )
end

nothing #hide
```
