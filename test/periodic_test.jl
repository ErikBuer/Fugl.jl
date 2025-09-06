using Fugl
using Fugl: Text, PeriodicCallback
using Dates

function main()
    # State for demonstrating periodic updates
    counter_state = Ref(0)
    last_file_check = Ref("Never")
    background_task_count = Ref(0)
    slow_task_result = Ref("Not started")

    # Create periodic callbacks with different intervals
    fast_counter_callback = PeriodicCallback(() -> begin
            counter_state[] += 1
            println("Fast counter: $(counter_state[])")
        end, 30)  # Every 30 frames (~0.5 seconds at 60fps)

    file_check_callback = PeriodicCallback(() -> begin
            last_file_check[] = string(now())
            println("Checking files at: $(last_file_check[])")
        end, 120)  # Every 120 frames (~2 seconds at 60fps)

    background_task_callback = PeriodicCallback(() -> begin
            background_task_count[] += 1
            # Simulate some background work
            println("Background task #$(background_task_count[]) completed")
        end, 60)  # Every 60 frames (~1 second at 60fps)

    slow_task_callback = PeriodicCallback(() -> begin
            # Simulate a slow periodic task
            result = "Task completed at $(now()) - iteration $(background_task_count[])"
            slow_task_result[] = result
            println("Slow task: $result")
        end, 300)  # Every 300 frames (~5 seconds at 60fps)

    function MyApp()
        IntrinsicColumn([
                IntrinsicHeight(Container(Text("Periodic Callback Demo"))),
                IntrinsicHeight(Container(Text("Frame-based periodic actions running in background"))),

                # Fast counter display
                IntrinsicHeight(Container(Text("Fast Counter (every 30 frames):"))),
                IntrinsicHeight(Container(Text("Count: $(counter_state[])"))),

                # File check status
                IntrinsicHeight(Container(Text("File Check (every 120 frames):"))),
                IntrinsicHeight(Container(Text("Last check: $(last_file_check[])"))),

                # Background task counter
                IntrinsicHeight(Container(Text("Background Tasks (every 60 frames):"))),
                IntrinsicHeight(Container(Text("Completed: $(background_task_count[])"))),

                # Slow task result
                IntrinsicHeight(Container(Text("Slow Task (every 300 frames):"))),
                IntrinsicHeight(Container(Text("$(slow_task_result[])"))),

                # Instructions
                IntrinsicHeight(Container(Text(""))),
                IntrinsicHeight(Container(Text("Watch the console for periodic callback messages!"))),
                IntrinsicHeight(Container(Text("Values update automatically via callbacks."))),
            ], padding=0.0, spacing=0.0)
    end

    # Run with multiple periodic callbacks
    Fugl.run(MyApp,
        title="Periodic Callback Demo",
        window_width_px=700,
        window_height_px=500,
        fps_overlay=true,
        periodic_callbacks=[
            fast_counter_callback,
            file_check_callback,
            background_task_callback,
            slow_task_callback
        ]
    )
end

main()