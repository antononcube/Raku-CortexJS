use v6.d;
unit class CortexJS::ComputeEngine;

use CortexJS::ComputeEngine::Backend::Node;

has CortexJS::ComputeEngine::Backend::Node $.backend is required;

multi method new(
    :$script is copy = Whatever,
    Str:D :$node = 'node',
    Real:D :$request-timeout = 10
) {
    if $script.isa(Whatever) { $script = %?RESOURCES<js/ce-bridge.mjs>.IO.Str }

    my $backend = CortexJS::ComputeEngine::Backend::Node.new(
        :$script,
        :$node,
        request-timeout => $request-timeout,
    ).start;

    self.bless(:$backend);
}

method ping() {
    $!backend.call('ping');
}

method version() {
    $!backend.call('version');
}

method parse-latex(Str:D $latex) {
    $!backend.call('parse_latex', latex => $latex);
}

method box($expr) {
    $!backend.call('box', expr => $expr);
}

method simplify($expr) {
    $!backend.call('simplify', expr => $expr);
}

method evaluate($expr) {
    $!backend.call('evaluate', expr => $expr);
}

method to-latex($expr) {
    $!backend.call('to_latex', expr => $expr);
}

method close() {
    $!backend.stop;
}

submethod DESTROY() {
    try $!backend.stop if $!backend.defined;
}
