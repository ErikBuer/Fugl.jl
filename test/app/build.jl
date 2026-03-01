#!/usr/bin/env julia

"""
Build script for apptest with JuliaC

This script:
1. Verifies font exists in source location
2. Compiles the app with JuliaC using the Julia API
3. Bundles the app with font assets
"""

using JuliaC

# Ensure we're in the right directory
script_dir = @__DIR__
repo_root = dirname(dirname(script_dir))
cd(repo_root)

println("Building testapp with JuliaC from: $(pwd())")

## Clean up old build directory
build_dir = joinpath(repo_root, "build")
if isdir(build_dir)
    println("Cleaning old build directory...")
    rm(build_dir, force=true, recursive=true)
end

## Verify font exists in source
font_src = joinpath(repo_root, "assets/fonts/FragmentMono-Regular.ttf")
if !isfile(font_src)
    error("Font file not found at: $(font_src)")
end
println("✓ Found font at: $(font_src)")

## Set up JuliaC recipes
println("\nConfiguring build...")

img = ImageRecipe(
    output_type="--output-exe",
    file="test/app/apptest.jl",  # Back to the real GUI app
    trim_mode="safe",
    add_ccallables=false,
    verbose=true,
)

link = LinkRecipe(
    image_recipe=img,
    outname="build/bin/slider_demo",  # Real GUI app name
    # rpath is set automatically when bundling
)

bun = BundleRecipe(
    link_recipe=link,
    output_dir="build", # bundle everything to build/
)

## Compile
println("\nCompiling...")
try
    compile_products(img)
    println("✓ Compilation successful")
catch e
    @error "Compilation failed" exception = e
    exit(1)
end

## Link
println("\nLinking...")
try
    link_products(link)
    println("✓ Linking successful")
catch e
    @error "Linking failed" exception = e
    exit(1)
end

## Bundle
println("\nBundling...")
try
    bundle_products(bun)
    println("✓ Bundling successful")
catch e
    @error "Bundling failed" exception = e
    exit(1)
end

## Copy font assets to bundle
println("\nCopying assets to bundle...")
font_dest_dir = joinpath(repo_root, "build/share/fonts")
mkpath(font_dest_dir)
font_dest = joinpath(font_dest_dir, "FragmentMono-Regular.ttf")

cp(font_src, font_dest, force=true)
println("✓ Copied font to: $(font_dest)")

println("\n" * "="^60)
println("✓ Build complete!")
println("="^60)
println("Run the GUI app with: ./build/bin/slider_demo")
