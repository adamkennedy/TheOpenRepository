use strict;
use warnings;
use Module::Build;

system("pod2text lib/XML/WiX3/Objects.pm >README") if -e 'MANIFEST.SKIP';

my $builder = Module::Build->new(
    module_name         => 'XML::WiX3::Objects',
    license             => 'perl',
    dist_author         => 'Curtis Jewell <csjewell@cpan.org>',
    dist_version_from   => 'lib/XML/WiX3/Objects.pm',
    requires => {
		'Moose' => 0.78,
		'MooseX::LogDispatch' => 0,
		'MooseX::Singleton' => 0,
        'Test::More' => 0,
        'version'    => 0.76,
		'Readonly' => 1.03,
    },
	recommends => {
		'MIME::Lite' => 3.020,
		'Readonly::XS' => 1.05,
		
	},
    add_to_cleanup      => [ 'XML-WiX3-Objects-*' ],
);

$builder->create_build_script();
