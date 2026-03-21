use v6.d;
unit class CortexJS::ComputeEngine;

use CortexJS::ComputeEngine::Backend::Node;

has CortexJS::ComputeEngine::Backend::Node $.backend is required;

multi method new(
    :$script is copy = Whatever,
    Str:D :$node = 'node',
    Real:D :$request-timeout = 10
) {
    if $script.isa(Whatever) {
        my $resource = %?RESOURCES<js/ce-bridge.mjs>;
        if $resource.defined {
            $script = $resource.slurp;
        } else {
            my $local = 'resources/js/ce-bridge.mjs'.IO.absolute;
            die 'Unable to resolve default bridge script from resources or local resources/js/ce-bridge.mjs'
                unless $local.IO.f;
            $script = $local.slurp;
        }
    }
    my $backend = CortexJS::ComputeEngine::Backend::Node.new(
        :$script,
        :$node,
        :$request-timeout,
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
    $!backend.call('parse_latex', :$latex);
}

method parse(Str:D $latex) {
    self.parse-latex($latex);
}

method box($expr) {
    $!backend.call('box', :$expr);
}

method simplify($expr) {
    $!backend.call('simplify', :$expr);
}

method assign($id, $expr) {
    $!backend.call('assign', :$id, :$expr);
}

method evaluate($expr) {
    $!backend.call('evaluate', :$expr);
}

method N($expr) {
    $!backend.call('n', :$expr);
}

method expand($expr) {
    $!backend.call('expand', :$expr);
}

method expandAll($expr) {
    $!backend.call('expand_all', :$expr);
}

method expand-all($expr) {
    self.expandAll($expr);
}

method factor($expr) {
    $!backend.call('factor', :$expr);
}

multi method solve($expr) {
    $!backend.call('solve', :$expr);
}

multi method solve($expr, $vars) {
    $!backend.call('solve', :$expr, :$vars);
}

method to-latex($expr) {
    $!backend.call('to_latex', :$expr);
}

method close() {
    $!backend.stop;
}

submethod DESTROY() {
    try $!backend.stop if $!backend.defined;
}
