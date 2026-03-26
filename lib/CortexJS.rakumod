use v6.d;
unit module CortexJS;

use CortexJS::ComputeEngine;
use LaTeX::Grammar;

our sub resources($key) {
    %?RESOURCES{$key}
}

#==========================================================
# Computation engine object
#==========================================================

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

# Clean up
END {
    $ce.close if $ce;
}

#==========================================================
# LaTeX functions
#==========================================================

sub parse-latex($expr) is export {
    start-ce() without $ce;
    return $ce.parse-latex($expr);
}

sub to-latex($expr,
             :$sep is copy = Whatever,
             Bool:D :b(:$bracketed) = True,
             Str:D :$left-bracket = '$',
             Str:D :$right-bracket = '$'
             ) is export {
    start-ce() without $ce;

    if $sep.isa(Whatever) { $sep = ', \: ' }
    die 'The argument $sep is expected to be a string or Whatever' unless $sep ~~ Str:D;

    my $res = do if $expr ~~ (Array:D | List:D | Seq:D) && $expr.all ~~ (Array:D | List:D | Seq:D | Numeric:D) {
        $expr.map({ $_ ~~ Numeric:D ?? $ce.to-latex(['Number', $_]) !! $ce.to-latex($_) }).join($sep)
    } else {
        $ce.to-latex($expr)
    }

    return $bracketed ?? $left-bracket ~ $res ~ $right-bracket !! $res;
}

#==========================================================
# Free symbolic functions
#==========================================================

our sub simplify($expr) is export {
    start-ce() without $ce;
    return $ce.simplify($expr);
}

our sub assign($id, $expr) is export {
    start-ce() without $ce;
    return $ce.simplify(:$id, $expr);
}

our sub evaluate($expr) is export {
    start-ce() without $ce;
    return $ce.evaluate($expr);
}

our sub N($expr) is export {
    start-ce() without $ce;
    return $ce.N($expr);
}

our sub expand($expr) is export {
    start-ce() without $ce;
    return $ce.expand($expr);
}

our sub expandAll($expr) is export {
    start-ce() without $ce;
    return $ce.expandAll($expr);
}

our &expand-all is export = &expandAll;

our sub factor($expr) is export {
    start-ce() without $ce;
    return $ce.factor($expr);
}

our proto sub solve($expr, |) is export {*}

multi sub solve($expr, $vars) {
    return solve($expr, :$vars);
}

multi sub solve($expr, :$vars) {
    start-ce() without $ce;
    return $ce.solve($expr, $vars);
}

multi sub solve($expr) {
    start-ce() without $ce;
    return $ce.solve($expr);
}

our sub cortex-js-call($func, $expr) is export {
    start-ce() without $ce;
    return $ce.call($func, $expr);
}

#==========================================================
# Wrappers
#==========================================================

# Using LaTeX::Grammar function &latex-parse to detect LaTeX input
my &is-latex-spec = { so latex-parse($_) }

our @wrappers;

our sub wrap-symbolic-subs() {
    return if @wrappers;

    @wrappers = [&simplify, &evaluate, &N, &expand, &expand-all, &expandAll, &factor].map({
        $_.wrap(-> $expr {
            my $is-latex = &is-latex-spec($expr);
            my $expr2 = $is-latex ?? parse-latex($expr) !! $expr;

            my $res = callwith($expr2);

            $is-latex ?? to-latex($res) !! $res;
        })
    });

    @wrappers.push(
            &solve.wrap(-> $expr, |c {
                my $is-latex = &is-latex-spec($expr);
                my $expr2 = $is-latex ?? parse-latex($expr) !! $expr;

                my $res = callwith($expr2, |c);

                $is-latex ?? to-latex($res) !! $res;
            })
    )
}

our sub unwrap-symbolic-subs() {
    return unless @wrappers;
    ([&simplify, &evaluate, &N, &expand, &expand-all, &expandAll, &factor, &solve] Z @wrappers).map({ $_.head.unwrap($_.tail) });
    @wrappers = Empty
}