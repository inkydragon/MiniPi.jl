# MiniPi

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://inkydragon.github.io/MiniPi.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://inkydragon.github.io/MiniPi.jl/dev/)
[![Build Status](https://github.com/inkydragon/MiniPi.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/inkydragon/MiniPi.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/inkydragon/MiniPi.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/inkydragon/MiniPi.jl)

## dev

### Gen code coverage locally

```sh
julia --project=test

using Pkg; using LocalCoverage;
Pkg.add(url=".");  html_coverage(generate_coverage("MiniPi"; run_test=true); dir = "../cov")
```