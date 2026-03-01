using GLAbstraction

image_path = GLAbstraction.dir("tutorials", "images")
if !isdir(image_path)
    mkdir(image_path)
end
urlbase = "https://open.gl/content/code/"
for (filename,remotefilename) in (("kitten.png","sample.png"),
                                  ("puppy.png", "sample2.png"))
    fullpath = joinpath(image_path, filename)
    if !isfile(fullpath)
        download(string(urlbase, remotefilename), fullpath)
    end
end
