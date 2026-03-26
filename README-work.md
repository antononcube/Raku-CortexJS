# Raku-CortexJS

[![Actions Status](https://github.com/antononcube/Raku-CortexJS/actions/workflows/linux.yml/badge.svg)](https://github.com/antononcube/Raku-CortexJS/actions)
[![Actions Status](https://github.com/antononcube/Raku-CortexJS/actions/workflows/macos.yml/badge.svg)](https://github.com/antononcube/Raku-CortexJS/actions)
[![Actions Status](https://github.com/antononcube/Raku-CortexJS/actions/workflows/windows.yml/badge.svg)](https://github.com/antononcube/Raku-CortexJS/actions)

[![](https://raku.land/zef:antononcube/CortexJS/badges/version)](https://raku.land/zef:antononcube/CortexJS)
[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)


Raku client for the [MathLive Cortex-JS Compute Engine](https://mathlive.io/compute-engine/).

----

## Installation

### Preliminary setup (Node.js and Node packages)

`CortexJS` starts a Node.js backend process and requires the
`@cortex-js/compute-engine` package to be available.

macOS (Homebrew):

```bash
brew install node
npm install @cortex-js/compute-engine
```

Linux (Debian/Ubuntu):

```bash
sudo apt update
sudo apt install -y nodejs npm
npm install @cortex-js/compute-engine
```

Windows (winget, PowerShell):

```powershell
winget install OpenJS.NodeJS.LTS
npm install @cortex-js/compute-engine
```

Verify:

```bash
node --version
npm list @cortex-js/compute-engine
```

### Raku package installation

Install this Raku package, "CortexJS", from Zef ecosystem:

```
zef install CortexJS
```

From GitHub:

```
zef install https://github.com/antononcube/Raku-CortexJS.git
```

-----

## How it works?

`CortexJS::ComputeEngine` is a Raku wrapper around a long-lived Node.js backend.
When you call `ComputeEngine.new`, the wrapper:

1. Resolves or loads the bridge JavaScript (`ce-bridge.mjs`) source.
2. Starts a Node process (`node ...`) through `Proc::Async`.
3. Initializes stream handlers for `stdout` (responses) and `stderr` (diagnostics).
4. Sends an initial `ping` request to confirm the backend is ready.

During the session, each Raku method call (for example `parse-latex`, `simplify`,
`evaluate`, `expand`, `solve`) is converted into a JSON request and written to the
Node process stdin. The bridge executes the operation with
`@cortex-js/compute-engine` and writes a JSON response back to stdout.
The Raku side matches responses and returns the decoded result to your code.

When done, call `.close` (or let object destruction trigger cleanup) to stop the
backend process.

```mermaid
flowchart TD
    A["Raku code: ComputeEngine.new()"] --> B["Resolve/load bridge JS source"]
    B --> C["Start Node backend process (Proc::Async)"]
    C --> D["Attach stdout/stderr handlers"]
    D --> E["Send ping"]
    E --> F{"Ping ok?"}
    F -- "No" --> G["Throw startup error"]
    F -- "Yes" --> H

    
    H{"Computations<br>finished?"} --> |No| I["Raku method call (parse/evaluate/simplify/...)"]
    I --> J["Serialize request as JSON line"]
    J --> K["Write request to Node stdin"]
    K --> L["Bridge executes CE operation"]
    L --> M["Write JSON response to stdout"]
    M --> N["Raku decodes and matches response"]
    N --> O["Return result to caller"]
    O --> H

    H --> |Yes|P["close() / DESTROY"]
    P --> Q["Close stdin + kill backend process"]
    
    subgraph RS["Computation Session"]
        H 
        I
        J
        K
        L
        M
        N
        O
    end
```

-----

## Basic usage

Make a new computation engine object and evaluate a LaTeX expression:

```raku, results=asis
use CortexJS;

'e^{i\\pi}' ==> evaluate()
```

Expand expression:

```raku, results=asis
'(a + b)^2' ==> expand()
```

Simplify expression:

```raku, results=asis
my $expr = parse-latex('3x^2 + 2x^2 + x + 5');
say "{to-latex($expr)} = {to-latex(simplify($expr))}";
```

Solve a symbolic equation

```raku, results=asis
'x^2 - a x + 1 = 0' ==> solve(vars => 'a')
```

The input can be both a LaTeX string (as above) or in [MathJSON format](https://mathlive.io/math-json/). 
Here the LaTeX expression `(a - b)^2` is converted to MathJSON using the sub `parse-latex`:

```raku
parse-latex('(a - b)^2').raku 
```

Here the corresponding MathJSON expression is expanded:

```raku
["Power", ["Add", "a", ["Negate", "b"]], 2]
==> expand()
```

MathJSON expressions can be converted to LaTeX with `to-latex`:

```raku, results=asis
_ ==> to-latex()
```

**Remark:** The "free functions" `evaluate`, `N`, `simplify`, `assign`, `expand`, `expandAll`, `factor`, and `solve`
verify (by parsing) is a string input a valid LaTeX code, and if the verification is successful, 
then (more or less) the following processing pipeline in applied: `$expr ==> parse-latex() ==> &func() ==> to-latex()`.

Using assignment for repeated expression evaluation:

```raku
my $expr = parse-latex("3x^2+4x+2");

for (0, 0.1 ... 1) -> $x {
  assign('x', $x);
  say "f($x) = {evaluate($expr)}";
}
```


----

## References

[ML1] MathLive.io, [Compute Engine](https://mathlive.io/compute-engine/).
