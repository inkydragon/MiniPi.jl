using MiniPi
using Documenter

DocMeta.setdocmeta!(MiniPi, :DocTestSetup, :(using MiniPi); recursive=true)

makedocs(;
    modules=[MiniPi],
    authors="Chengyu HAN <git@wo-class.cn> and contributors",
    sitename="MiniPi.jl",
    format=Documenter.HTML(;
        canonical="https://inkydragon.github.io/MiniPi.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/inkydragon/MiniPi.jl",
    devbranch="main",
)
