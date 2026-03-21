use v6.d;
unit module CortexJS;

use CortexJS::ComputeEngine;

our sub resources($key) {
    %?RESOURCES{$key}
}

my $ce = Whatever;

sub start-ce() {
    my $startup-error = '';
    try {
        $ce = CortexJS::ComputeEngine.new;
        CATCH {
            default {
                $startup-error = .Str;
                die $startup-error;
            }
        }
    }
}

sub parse-latex($expr) is export {
    start-ce() without $ce;
    return $ce.parse-latex($expr);
}

sub simplify($expr) is export {
    start-ce() without $ce;
    return $ce.simplify($expr);
}

sub assign($id, $expr) is export {
    start-ce() without $ce;
    return $ce.simplify(:$id, $expr);
}

sub evaluate($expr) is export {
    start-ce() without $ce;
    return $ce.evaluate($expr);
}

sub N($expr) is export {
    start-ce() without $ce;
    return $ce.N($expr);
}

sub expand($expr) is export {
    start-ce() without $ce;
    return $ce.expand($expr);
}

sub expandAll($expr) is export {
    start-ce() without $ce;
    return $ce.expandAll($expr);
}

our &expand-all is export = &expandAll;

sub factor($expr) is export {
    start-ce() without $ce;
    return $ce.factor($expr);
}

proto sub solve($expr, |) is export {*}

multi sub solve($expr, Str:D $var) {
    return solve($expr, [$var,]);
}

multi sub solve($expr, @vars) {
    start-ce() without $ce;
    return $ce.solve($expr, @vars.join(', '));
}

multi sub solve($expr) {
    start-ce() without $ce;
    return $ce.solve($expr);
}

sub to-latex($expr) is export {
    start-ce() without $ce;
    return $ce.to-latex($expr);
}

END {
    $ce.close if $ce;
}