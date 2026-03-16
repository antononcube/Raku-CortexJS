use v6.d;
unit class CortexJS::ComputeEngine::Backend::Node;

use JSON::Fast;

has Str $.node = 'node';
has Str $.script is required;
has Real $.request-timeout = 10;

has Proc::Async $!proc;
has Bool $!running = False;
has Int $!next-id = 1;
has Lock $!call-lock .= new;
has Channel $!responses .= new;
has Str $!stdout-buffer = '';

method !chunk-text($chunk --> Str) {
    $chunk ~~ Blob ?? $chunk.decode('utf8') !! $chunk.Str;
}

method !build-proc() {
    if $!script.IO.f {
        return Proc::Async.new($!node, $!script, :w);
    }

    # Treat $.script as inline ESM source code.
    return Proc::Async.new($!node, '--input-type=module', '--eval', $!script, :w);
}

method start() {
    return self if $!running;

    $!proc = self!build-proc;
    self!wire-streams;

    try { $!proc.start; }
    CATCH {
        default {
            $!running = False;
            die "Failed to start backend process: {.Str}";
        }
    }

    $!running = True;

    self.call('ping', :timeout(2));
    self
}

method !wire-streams() {
    $!proc.stdout.tap(-> $chunk {
        $!stdout-buffer ~= self!chunk-text($chunk);

        loop {
            my $newline = $!stdout-buffer.index("\n");
            last unless $newline.defined;

            my $line = $!stdout-buffer.substr(0, $newline).trim;
            $!stdout-buffer = $!stdout-buffer.substr($newline + 1);
            next unless $line.chars;

            try {
                my %decoded = from-json($line);
                $!responses.send(%decoded);
            }
            CATCH {
                default {
                    $!responses.send({
                        id => Nil,
                        ok => False,
                        error => {
                            name => 'DecodeError',
                            message => .Str,
                        },
                    });
                }
            }
        }
    });

    $!proc.stderr.tap(-> $chunk {
        note "ce-backend stderr: " ~ self!chunk-text($chunk).trim;
    });
}

method !ensure-running() {
    die 'Backend is not running. Call .start first.' unless $!running;
}

method call(Str:D $op, *%args, Real:D :$timeout = $!request-timeout) {
    self!ensure-running;

    $!call-lock.protect({
        my $id = $!next-id++;
        my $json = to-json({
            id => $id,
            op => $op,
            args => %args.Hash,
        }, :!pretty);

        $!proc.say: $json;

        my $response-promise = start { $!responses.receive };
        await Promise.anyof($response-promise, Promise.in($timeout));

        unless $response-promise.status ~~ Kept {
            die "Timed out waiting for backend response to op '$op' after {$timeout}s";
        }

        my %response = $response-promise.result;

        if %response<ok> {
            return %response<result>;
        }

        my %error = %response<error>:exists ?? %response<error>.Hash !! Hash.new;
        my $name = %error<name> // 'BackendError';
        my $message = %error<message> // 'unknown backend error';
        die "{$name}: {$message}";
    });
}

method stop() {
    return unless $!proc.defined;

    $!running = False;
    try $!proc.close-stdin;
    try $!proc.kill;
}
