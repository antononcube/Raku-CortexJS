# Raku-CortexJS

[![Actions Status](https://github.com/antononcube/Raku-CortexJS/actions/workflows/linux.yml/badge.svg)](https://github.com/antononcube/Raku-CortexJS/actions)
[![Actions Status](https://github.com/antononcube/Raku-CortexJS/actions/workflows/macos.yml/badge.svg)](https://github.com/antononcube/Raku-CortexJS/actions)
[![Actions Status](https://github.com/antononcube/Raku-CortexJS/actions/workflows/windows.yml/badge.svg)](https://github.com/antononcube/Raku-CortexJS/actions)

[![](https://raku.land/zef:antononcube/CortexJS/badges/version)](https://raku.land/zef:antononcube/CortexJS)
[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)


Raku client for the [MathLive Cortex-JS Compute Engine](https://mathlive.io/compute-engine/).

----

## Installation

From Zef ecosystem:

```
zef install CortexJS
```

From GitHub:

```
zef install https://github.com/antononcube/Raku-CortexJS.git
```

-----

## Basic usage

```raku
use CortexJS;
my $ce = ComputeEngine.new;

#$ce.expand($ce.parse-latex('(a + b)^2'))
$ce.evaluate($ce.parse-latex('e^{i\\pi}'))
```

```raku
LEAVE $ce.close;

my $expr = $ce.parse-latex('3x^2 + 2x^2 + x + 5');
say "{$ce.to-latex($expr)} = {$ce.to-latex($ce.simplify($expr))}";
```

----

## References