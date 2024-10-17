using MiniPi
using Documenter

DocMeta.setdocmeta!(MiniPi, :DocTestSetup, :(using MiniPi); recursive=true)

makedocs(;
    modules=[MiniPi],
    authors="Chengyu HAN <cyhan.dev@outlook.com> and contributors",
    sitename="MiniPi.jl",
    format=Documenter.HTML(;
        canonical="https://inkydragon.github.io/MiniPi.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    checkdocs=:exports,
)

deploydocs(;
    repo="github.com/inkydragon/MiniPi.jl",
    devbranch="main",
)
