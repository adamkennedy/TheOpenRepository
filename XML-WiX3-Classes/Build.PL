use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WiX3',
    license             => 'perl',
    dist_author         => 'Curtis Jewell <csjewell@cpan.org>',
    dist_version_from   => 'lib/WiX3.pm',
	create_makefile_pl  => 'passthrough',
	create_readme       => 1,
    requires => {
		'Moose' => 0.76,
		'MooseX::LogDispatch' => 0,
		'MooseX::Singleton' => 0,
		'MooseX::Types' => 0,
		'MooseX::AttributeHelpers' => 0,
		'MooseX::NonMoose' => 0,
		'Regexp::Common' => 0,
        'Test::More' => 0,
        'version'    => 0.76,
		'Readonly' => 1.03,
    },
	recommends => {
		'MIME::Lite' => 3.020,
		'Readonly::XS' => 1.05,
		
	},
    add_to_cleanup      => [ 'XML-WiX3-Classes-*' ],
);

$builder->create_build_script();
