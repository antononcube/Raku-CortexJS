use v6.d;

# The Cortex-JS Compute Engine can be used in Raku via a 
# CortexJS::ComputationEngine object or by "free functions", 
# https://mathlive.io/compute-engine/#free-functions
# This file shows the use with free functions.

# use lib <. lib>;
use CortexJS;

my $parsed = parse-latex('x^2+2x+1');
say "parsed: " ~ $parsed.raku;
say "parsed latex: " ~ to-latex($parsed);

my $simplified = simplify(["Add", ["Power", "x", 1], ["Multiply", 2, "x"], 1]);
say "simplified: " ~ $simplified.raku;
say "simplified latex: " ~ to-latex($simplified);

my $evaluated = evaluate(["Sin", ["Divide", "Pi", 2]]);
say "evaluated: " ~ $evaluated.raku;
say "evaluated latex: " ~ to-latex($evaluated);
