use Module::Build;

my $mb = Module::Build->new(
  module_name   => 'Data::ValidateInterdependent',
  license       => 'perl',
  requires      => {
      Carp      => 0,
      Moo       => 0,
      perl      => '5.14.0',
      warnings  => 0,
  },
);

$mb->create_build_script;
