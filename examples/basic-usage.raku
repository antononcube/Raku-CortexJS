use v6.d;

use lib <. lib>;
use CortexJS;

#my $root = $*PROGRAM.parent.parent.absolute;
#my $script = $root.child('resources/js/ce-bridge.mjs').Str;
#
#my $ce = ComputeEngine.new(:$script);
#LEAVE $ce.close;

my $script = 'resources/js/ce-bridge.mjs'.IO.absolute.Str;
my $ce;
my $startup-error = '';
try {
    $ce = CortexJS::ComputeEngine.new(:$script);
    CATCH {
        default {
            $startup-error = .Str;
        }
    }
}


LEAVE { try $ce.close if $ce.defined; }

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
