use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name  => 'PITA::Test::Dummy::Perl5::Build',
    license      => 'perl',
    dist_author  => 'Adam Kennedy <cpan@ali.as>',
    dist_version => '1.00',
);

$builder->create_build_script();
