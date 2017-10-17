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

has _expected_params => (
    is => 'ro',
    default => sub { {} },
);

has _ignore_unknown => (
    is => 'rw',
    default => 0,
);

sub _parse_params {
    my ($spec) = @_;
    return @$spec if ref $spec eq 'ARRAY';
    return $spec;
}

sub _declare_variable {
    my ($self, @names) = @_;

    my $known = $self->_variables;
    for my $var (@names) {
        if ($known->{$var}) {
            croak qq(Variable cannot be declared twice: $var);
        }
        else {
            $known->{$var} = 1;
        }
    }

    return;
}

sub _declare_param {
    my ($self, @names) = @_;
    my $expected_params = $self->_expected_params;

    $expected_params->{$_} = 1 for @names;

    return;
}

=head2 const

TODO

=cut

sub const {
    my ($self, %values) = @_;
    _declare_variable($self, sort keys %values);
    push @{ $self->_rules }, [const => \%values];
    return $self;
}

=head2 param

TODO

=cut

sub param {
    my ($self, @items) = @_;

    my %mapping;
    for my $item (@items) {
        $item = { $item => $item } if ref $item ne 'HASH';
        @mapping{ keys %$item } = values %$item;
    }

    _declare_param($self, sort values %mapping);
    _declare_variable($self, sort keys %mapping);

    push @{ $self->_rules }, [param => \%mapping];

    return $self;
}

=head2 validate

TODO

=cut

sub validate {
    my ($self, $output, $input, $callback) = @_;
    $output = [_parse_params($output)];
    $input = [_parse_params($input)];

    my @vars;
    my @args;
    for (@$input) {
        if (/^\$/) {
            push @args, s/^\$//r;
        }
        else {
            push @vars, $_;
        }
    }

    _declare_param($self, @args) if @args;

    my $known_variables = $self->_variables;

    if (my @unknown = grep { not $known_variables->{$_} } @vars) {
        croak qq(Validation rule "@$output" depends on undeclared variables: ), join q(, ) => sort @unknown;
    }

    _declare_variable($self, @$output);

    push @{ $self->_rules }, [rule => $output, $input, $callback];
    return $self;
}

=head2 run

    my $validated = $v->run(%params);

TODO

B<Returns:> a hashref with all variables.

B<Throws:> when unknown parameters were provided.

=cut

sub run {
    my ($self, %params) = @_;

    unless ($self->_ignore_unknown) {
        my $expected_params = $self->_expected_params;
        if (my @unknown = grep { not $expected_params->{$_} } keys %params) {
            croak qq(Unknown parameters: ), join q(, ) => sort @unknown;
        }
    }

    my %variables;

    my $get_arg = sub {
        my ($name) = @_;
        return $params{$name} if $name =~ s/^\$//;
        return $variables{$name};
    };

    RULE:
    for my $rule (@{ $self->_rules }) {
        my ($type, @rule_args) = @$rule;

        if ($type eq 'const') {
            my ($values) = @rule_args;
            @variables{keys %$values} = values %$values;
            next RULE;
        }

        if ($type eq 'param') {
            my ($mapping) = @rule_args;
            @variables{ keys %$mapping } = @params{ values %$mapping };
            next RULE;
        }

        if ($type eq 'rule') {
            my ($provided, $required, $callback) = @rule_args;

            my $result = $callback->(map { $get_arg->($_) } @$required);

            for my $var (@$provided) {
                if (exists $result->{$var}) {
                    $variables{$var} = delete $result->{$var};
                }
                else {
                    croak qq(Validation rule "@$provided" must return parameter $var);
                }
            }

            if (my @unknown = keys %$result) {
                croak qq(Validation rule "@$provided" returned unknown variables: ),
                    join q(, ) => sort @unknown;
            }

            next RULE;
        }

        die "Unknown rule type: $type";
    }

    return \%variables;
}

=head2 ignore_unknown

    $v->ignore_unknown;

TODO

=cut

sub ignore_unknown {
    my ($self) = @_;
    $self->_ignore_unknown(1);
    return $self;
}

=head2 provided

    my @names = $v->provided;

TODO

=cut

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
