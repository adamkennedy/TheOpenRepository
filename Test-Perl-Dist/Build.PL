use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Perl::Dist',
    license             => 'perl',
    dist_author         => 'Curtis Jewell <CSJewell@cpan.org>',
    dist_version_from   => 'lib/Test/Perl/Dist.pm',
	dist_abstract       => 'Test module for Perl::Dist::WiX and subclasses',
	create_readme       => 1,
	create_license      => 1,
	create_makefile_pl  => 'passthrough',
	configure_requires  => {
        'Module::Build'      => 0.33,
	},
    requires => {
	    'perl'               => 5.008001,
		'parent'             => 0.221,
		'File::Remove'       => 1.42,
		'LWP::Online'        => 1.07,
		'Test::More'         => 0.88,
		'URI'                => 1.40,
		'Win32'              => 0.39,
    },
	build_requires      => {
        'Test::More'         => 0.88,
	},
	meta_merge     => {
        resources  => {
            homepage    => 'http://csjewell.comyr.com/perl/',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Perl-Dist',
            repository  => 'http://svn.ali.as/cpan/trunk/Test-Perl-Dist/'
        },
    },
    add_to_cleanup      => [ 'Test-Perl-Dist-*', ],
);

$builder->create_build_script();
