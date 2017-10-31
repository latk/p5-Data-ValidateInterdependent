# NAME

Data::ValidateInterdependent - safely validate interdependent parameters

# SYNOPSIS

    use Data::ValidateInterdependent;

    state $validator =
        Data::ValidateInterdependent->new
        # inject a constant value
        ->const(generator => 'perl')
        # take an input parameter without validation
        ->param('description')
        # create variables "x", "y", "z" from parameter "coords"
        ->validate(['x', 'y', 'z'], '$coords', sub {
            my ($coords) = @_;
            die "Coords must contain 3 elements" unless @$coords == 3;
            my ($x, $y, $z) = @$coords;
            return { x => $x, y => $y, z => $z };
        })
        # create variable "title" from parameter "title"
        # and from validated variables "x", "y", "z".
        ->validate('title', ['$title, 'x', 'y', 'z'], sub {
            my ($title, $x, $y, $z) = @_;
            $title //= "Object at ($x, $y, $z)";
            return { title => $title };
        });

    my $variables = $validator->run(%config);

# DESCRIPTION

The problem: you need to validate some configuration.
But validation of one field depends on other fields,
or default values are taken from other parts of the config.
These dependencies can be daunting.

This module makes the dependencies between different validation steps
more explicit:
Each step declares which variables it provides,
and which variables or input parameters it consumes.
The idea of
[Static Single Assignment](https://en.wikipedia.org/wiki/Static_single_assignment_form)
allows us to check basic consistency properties when the validator is assembled:

- The validator will provide all declared output variables.
Because there is no branching,
it is not possible to forget a variable.
- All variables are declared before they are used.
It is not possible to accidentally read an unvalidated value.
- Each variable is only initialized once.
It is not possible to accidentally overwrite a variable.

## Terminology

A **parameter** is an unvalidated input value.
A parameter called `name` can be addressed with the symbol `$name`,
i.e. with a prepended `$` character.
If no such parameter exists, its value will be `undef`.

A **variable** is a validated field that will be written exactly once.
A variable called `name` is addressed with the symbol `name`,
i.e. without any changes.

A **validation rule** is a callback that initializes one or more variables.
It receives a list with any number of parameters and variables.

# METHODS

Unless explicitly noted,
all methods return the object itself
so that you can chain methods.

## const

    $validator = $validator->const(name => $value, ...);

Declare one or more variables with a constant value.

In most cases this is not necessary
because you could use Perl variables
to make data accessible to all pipeline steps.

Note that this method cannot provide default values for a variable,
since all variables are write-once.

This method is functionally equivalent to:

    $validator->validate(['name', ...], [], sub {
        return { name => $value, ... };
    });

## param

    $validator = $validator->param('name', { variable => 'parameter' }, ...);

Declare variables that take their value directly from input parameters
without any validation.

The arguments may be variable names,
in which case the value is taken from the parameter of the same name.
The arguments may also be a hash ref,
which maps variable names to parameters.
These names are not symbols,
so you must not include the `$` for parameter symbols.

Absolutely no validation will be performed.
If the parameter does not exist, the variable will be `undef`.

This method is functionally equivalent to:

    $validator->validate(['name', 'variable', ...], ['$name', '$parameter'], sub {
        my ($name, $parameter, ...) = @_;
        return { name => $name, variable => $parameter, ... };
    });

## validate

    $validator = $validator->validate($output, $input, sub { ... });

Perform a validation step.

**$output** declares the variables which are assigned by this validation step.
It may either be a single variable name,
or an array ref with one or more variable names.

**$input** declares dependencies on other variables or input parameters.
It may either be a single symbol,
or an array ref of symbols.
The array ref may be empty.
A symbol can be the name of a variable,
or a `$` followed by the name of a parameter.

**sub { ... }** is a callback that peforms the validation step.
The callback will be invoked with the values of all _$input_ symbols,
in the order in which they were listed.
Note that a parameter will have `undef` value if it doesn't exist.
The callback must return a hash ref that contains all variables to be assigned.
The hash keys must match the declared _$output_ variables exactly.

The returned hash ref will be modified.
If other code depends on this hash ref, return a copy instead.

**Throws** when an existing variable was re-declared.
All variables are write-once.
You cannot reassign them.

**Throws** when an undeclared variable was used.
You must declare all variables before you can use them.

**Example:** Reading multiple inputs:

    # "x" and "y" are previously declared variables.
    # "foo" is an input parameter.
    $validator->validate('result', ['x', '$foo', 'y'], sub {
        my ($x, $foo, $y) = @_;
        $foo //= $y;
        return { result => $x + $foo };
    });

## run

    my $variables = $validator->run(%params);

Run the validator with a given set of params.
A validator instance can be run multiple times.

**%params** is a hash of all input parameters.
The hash may be empty.

**Returns:** a hashref with all output variables.
If your validation rules assigned helper variables,
you may want to delete them from this hashref before further processing.

**Throws:** when unknown parameters were provided
(but see [ignore\_unknown()](#ignore_unknown)).

**Throws:** when a rule callback did not return a suitable value:
either it was not a hash ref,
or the hash ref did not assign exactly the $output variables.

## ignore\_unknown

    $validator = $validator->ignore_unknown;

Ignore unknown parameters.
If this flag is not set, the [run()](#run) method will die
when unknown parameters were provided.
A parameter is unknown when no validation rule or param assignment
reads from that parameter.

## ignore\_param

    $validator = $validator->ignore_param($name, ...);

Ignore a specific parameter.

## provided

    my @names = $validator->provided;

Get a list of all provided variables.
The order is unspecified.

## unused

    my @names = $validator->unused;

Get a list of all variables that are provided but not used.
The order is unspecified.

## select

    $validator = $validator->select(@names);

Mark variables as used, and ensure that these variables exist.

This is convenient when the validator is assembled in different places,
and you want to make sure that certain variables are provided.

The output variables may include variables that were not selected.
This method does not list all output variables,
but just ensures their presence.

# SUPPORT

Homepage: [https://github.com/latk/p5-Data-ValidateInterdependent](https://github.com/latk/p5-Data-ValidateInterdependent)

Bugtracker: [https://github.com/latk/p5-Data-ValidateInterdependent/issues](https://github.com/latk/p5-Data-ValidateInterdependent/issues)

# AUTHOR

amon – Lukas Atkinson (cpan: AMON) <amon@cpan.org>

# COPYRIGHT

Copyright 2017 Lukas Atkinson

This library is free software and may be distributed under the same terms
as perl itself. See http://dev.perl.org/licenses/.
