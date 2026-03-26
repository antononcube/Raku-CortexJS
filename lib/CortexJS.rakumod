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
# LaTeX pipeline
#==========================================================

# Using LaTeX::Grammar function &latex-parse to detect LaTeX input
my &is-latex-spec = { so latex-parse($_) }

sub latex-pipeline(Str:D $func, Str:D $expr, *@args, *%args) {
    my $is-latex = &is-latex-spec($expr);
    die 'Cannot parsr the given string as LaTeX code.' unless $is-latex;

    return do if $is-latex {
        my $expr2 = parse-latex($expr);

        my @named-args = &to-latex.candidates».signature».params.map({ $_.grep(*.named)».name}).flat.unique;

        my %args2 = %args.grep({ $_ ∉ @named-args });
        my $res = ::("&{$func}")($expr2, |@args, |%args2);

        %args2 = %args.grep({ $_ ∈ @named-args });
        to-latex($res, |%args2)
    } else {
        # Currently this won't be reached, but I want to
        # use this block of JSON strings that are valid MathJSON expressions.
        my $res = ::("&{$func}")($expr, |@args, |%args);
    }
}

#==========================================================
# Free symbolic functions
#==========================================================

#| Simplify an expression, MathJSON or LaTeX.
our proto sub simplify($expr, |) is export {*}

multi sub simplify(Str:D $expr, *%args) {
    latex-pipeline('simplify', $expr, |%args)
}

multi sub simplify($expr) {
    start-ce() without $ce;
    return $ce.simplify($expr);
}

#| Assign to a symbol with name $id the the expression, $expr (MathJSON or LaTeX.)
our proto sub assign($id, $expr, |) is export {*}

multi sub assign($id, Str:D $expr, *%args) {
    latex-pipeline('assign', $expr, :$id, |%args)
}

multi sub assign($id, $expr) {
    start-ce() without $ce;
    return $ce.simplify(:$id, $expr);
}

multi sub assign($expr, :$id) {
    start-ce() without $ce;
    return $ce.simplify(:$id, $expr);
}

#| Evaluate an expression, MathJSON or LaTeX.
our proto sub evaluate($expr, |) is export {*}

multi sub evaluate(Str:D $expr, *%args) {
    latex-pipeline('evaluate', $expr, |%args)
}

multi sub evaluate($expr) {
    start-ce() without $ce;
    return $ce.evaluate($expr);
}

#| Numerical value of an expression, MathJSON or LaTeX.
our proto sub N($expr, |) is export {*}

multi sub N($id, Str:D $expr, *%args) {
    latex-pipeline('N', $expr, |%args)
}

multi sub N($expr) {
    start-ce() without $ce;
    return $ce.N($expr);
}

#| Expand an expression, MathJSON or LaTeX.
our proto expand($expr, |) is export {*}

multi sub expand(Str:D $expr, *%args) {
    latex-pipeline('expand', $expr, |%args)
}

multi sub expand($expr) {
    start-ce() without $ce;
    return $ce.expand($expr);
}

#| Expand an expression, MathJSON or LaTeX.
our proto sub expandAll($expr, |) is export {*}

multi sub expandAll(Str:D $expr, *%args) {
    latex-pipeline('expandAll', $expr, |%args)
}

multi sub expandAll($expr) {
    start-ce() without $ce;
    return $ce.expandAll($expr);
}

our &expand-all is export = &expandAll;


#| Factor an expression, MathJSON or LaTeX.
our proto sub factor($expr, |) is export {*}

multi sub factor(Str:D $expr, *%args) {
    latex-pipeline('factor', $expr, |%args)
}

multi sub factor($expr) {
    start-ce() without $ce;
    return $ce.factor($expr);
}

#| Solve an equation, MathJSON or LaTeX.
our proto sub solve($expr, |) is export {*}

multi sub solve(Str:D $expr, *@args, *%args) {
    latex-pipeline('solve', $expr, |@args, |%args)
}

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

#| Invoke a function over an expression, MathJSON or LaTeX.
our proto sub cortex-js-call($func, $expr, |) is export {*}

multi sub cortex-js-call($func, Str:D $expr, *%args) {
    latex-pipeline('cortex-js-call', $expr, :$func, |%args)
}

multi sub cortex-js-call($expr, :$func) {
    cortex-js-call($func, $expr)
}

multi sub cortex-js-call($func, $expr) {
    start-ce() without $ce;
    return $ce.call($func, $expr);
}

#==========================================================
# Wrappers
#==========================================================
# Not needed but I want to keep it as a reference for now.
#`[
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
]