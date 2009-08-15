use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Module::Starter::CSJEWELL',
    license             => 'perl',
    dist_author         => 'Curtis Jewell <CSJewell@cpan.org>',
    dist_version_from   => 'lib/Module/Starter/CSJEWELL.pm',
	create_readme            => 1,
	create_license           => 1,
	create_makefile_pl       => 'passthrough',
	configure_requires  => {
        'Module::Build'       => '0.33',
	},
    requires => {
	    'perl'              => 5.008001,
        'Module::Starter'   => '1.52',
		'parent'            => '0.221',
		'Software::License' => '0.012',
		'Pod::Readme'       => '0.09',
    },
	build_requires      => {
        'Test::More'        => '0.61',
	},
	meta_merge     => {
        resources => {
            homepage    => 'http://csjewell.comyr.com/perl/',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Starter-CSJEWELL',
            repository  => 'http://svn.ali.as/cpan/trunk/Module-Starter-CSJEWELL/'
        },
    },
    add_to_cleanup      => [ 'Module-Starter-CSJEWELL-*', ],
);

$builder->create_build_script();
