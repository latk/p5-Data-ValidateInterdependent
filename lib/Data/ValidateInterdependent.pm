package Data::ValidateInterdependent;
use utf8;
use v5.14;
use warnings;
our $VERSION = '0.000001';

use Moo;
use Carp;

=encoding UTF-8

=head1 NAME

Data::ValidateInterdependent - safely validate interdependent parameters

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

Uses static single assignment (SSA) to verify consistency.

A Rule is a List[Variable] => List[Variable] transformation.

=head1 METHODS

=cut

# the static environment
has _variables => (
    is => 'ro',
    default => sub { {} },
);

has _rules => (
    is => 'ro',
    default => sub { [] },
);

has _required_parameters => (
    is => 'ro',
    default => sub { {} },
);

=head2 const

TODO

=cut

sub const {
    my ($self, %values) = @_;
    ...
}

=head2 param

TODO

=cut

sub param {
    my ($self, @params) = @_;
    ...
}

=head2 validate

TODO

=cut

sub validate {
    my ($self, $output, $input, $callback) = @_;
    ...
}

=head2 run

TODO

=cut

sub run {
    my ($self, %params) = @_;
    ...
}

=head1 SUPPORT

Homepage: L<https://github.com/latk/p5-Data-ValidateInterdependent>

Bugtracker: L<https://github.com/latk/p5-Data-ValidateInterdependent/issues>

=head1 AUTHOR

amon – Lukas Atkinson (cpan: AMON) <amon@cpan.org>

=head1 COPYRIGHT

Copyright 2017 Lukas Atkinson

This library is free software and may be distributed under the same terms
as perl itself. See http://dev.perl.org/licenses/.

=cut

1;
