use v6.d;

# use lib <. lib>;
use CortexJS;

my $ce = ComputeEngine.new;
LEAVE $ce.close;

say "ping: " ~ $ce.ping.raku;
say "version: " ~ $ce.version.raku;

my $parsed = $ce.parse-latex('x^2+2x+1');
say "parsed: " ~ $parsed.raku;
say "parsed latex: " ~ $ce.to-latex($parsed);

my $simplified = $ce.simplify(["Add", ["Power", "x", 1], ["Multiply", 2, "x"], 1]);
say "simplified: " ~ $simplified.raku;
say "simplified latex: " ~ $ce.to-latex($simplified);

my $evaluated = $ce.evaluate(["Sin", ["Divide", "Pi", 2]]);
say "evaluated: " ~ $evaluated.raku;
say "evaluated latex: " ~ $ce.to-latex($evaluated);
