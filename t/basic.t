#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Data::ValidateInterdependent';

sub new { Data::ValidateInterdependent->new(@_) }

subtest q(it can be empty) => sub {
    my $valid = new->run();
    is_deeply $valid, {};
};

subtest q(it rejects unknown params) => sub {
    throws_ok { new->run(foo => 42, bar => 42) }
        qr/^Unknown parameters: bar, foo at /;
};

subtest q(it does not die when unknowns are ignored) => sub {
    my $valid = new->ignore_unknown->run(x => 1, y => 2, z => 3);
    is_deeply $valid, {};
};

subtest q(it can add constant values) => sub {
    my $valid = new->const(x => 'a', b => 3)->run();
    is_deeply $valid, { b => 3, x => 'a' };
};

subtest q(rule can provide calculated values) => sub {
    my $valid = new
        ->validate('x', [], sub {
            return { x => 17 },
        })
        ->run();
    is_deeply $valid, { x => 17 };
};

subtest q(rule can return multiple variables) => sub {
    my $valid = new
        ->validate(['x', 'y'], [], sub {
            return { x => 3, y => 5 };
        })
        ->run();
    is_deeply $valid, { x => 3, y => 5 },
};

subtest q(rule can only provide declared variables) => sub {
    my $v = new
        ->validate(['y', 'x'], [], sub {
            return { x => 17, y => 3, a => 9, b => 42 };
        });
    throws_ok { $v->run() }
        qr/^Validation rule "y x" returned unknown variables: a, b at /;
};

subtest q(rule must provide all declared variables) => sub {
    my $v = new
        ->validate(['y', 'x'], [], sub {
            return { x => 3 };
        });

    throws_ok { $v->run() }
        qr/Validation rule "y x" must return parameter y at /;
};

subtest q(rule can use parameters) => sub {
    my $valid = new
        ->validate('y', '$x', sub {
            my ($x) = @_;
            return { y => $x + 3 };
        })
        ->run(x => 10);
    is_deeply $valid, { y => 13 };
};

subtest q(rule can use previous variables) => sub {
    my $valid = new
        ->validate('x', [], sub {
            return { x => 10 };
        })
        ->validate('y', 'x', sub {
            my ($x) = @_;
            return { y => $x + 3 };
        })
        ->run;
    is_deeply $valid, { x => 10, y => 13 };
};

subtest q(rule dependencies must have been declared) => sub {
    throws_ok { new->validate(['y', 'x'], ['b', 'a'], sub { ... }) }
        qr/Validation rule "y x" depends on undeclared variables: a, b at /;
};

subtest q(rule dependency cannot be declared twice) => sub {
    my $v = new->validate('x', [], sub { ... });
    throws_ok { $v->validate('x', [], sub { ... }) }
        qr/Variable cannot be declared twice: x at /;
};

subtest q(const values also count as declared variable) => sub {
    my $valid = new
        ->const(foo => 3)
        ->validate('bar', 'foo', sub {
            my ($foo) = @_;
            return { bar => $foo + 10 };
        })
        ->run;
    is_deeply $valid, { foo => 3, bar => 13 };
};

subtest q(it can consume params) => sub {
    my $valid = new
        ->param('a', { b => 'x', c => 'y' })
        ->run(a => 1, x => 3, y => 7);
    is_deeply $valid, { a => 1, b => 3, c => 7 };
};

subtest q(params also count as declared variable) => sub {
    my $valid = new
        ->param('x')
        ->validate('a', 'x', sub {
            my ($x) = @_;
            return { a => $x * 4 };
        })
        ->run(x => 2);
    is_deeply $valid, { x => 2, a => 8 };
};

done_testing;
