# MiniPi

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://inkydragon.github.io/MiniPi.jl/dev/)
[![Build Status](https://github.com/inkydragon/MiniPi.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/inkydragon/MiniPi.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/inkydragon/MiniPi.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/inkydragon/MiniPi.jl)

> A miniature program that can compute Pi to millions of digits.
> —— [Mini-Pi][Mini-Pi] in Pure Julia.

[Mini-Pi]: https://github.com/Mysticial/Mini-Pi


## dev

### Gen code coverage locally

```sh
julia --project=test

using Pkg; using LocalCoverage;
Pkg.add(url=".");  html_coverage(generate_coverage("MiniPi"; run_test=true); dir = "../cov")
```


## License

```c
// SPDX-License-Identifier: MIT
```

> The original [Mysticial/Mini-Pi](https://github.com/Mysticial/Mini-Pi)
> was written in C++ under the CC0-1.0 licence.
