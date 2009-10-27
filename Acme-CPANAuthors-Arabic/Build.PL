use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Acme::CPANAuthors::Arabic',
	license             => 'perl',
	dist_author         => 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>',
	dist_version_from   => 'lib/Acme/CPANAuthors/Arabic.pm',
	requires => {
		'perl'              => '5.008',
		'Acme::CPANAuthors' => '0.09',
	},
	build_requires => {
		'Test::More' => 0,
	},
	add_to_cleanup      => [ 'Acme-CPANAuthors-Arabic-*' ],
	meta_merge         => {
		resources => {
			repository =>
				'http://svn.ali.as/cpan/trunk/Acme-CPANAuthors-Arabic',
		}
	},
);

$builder->create_build_script();
