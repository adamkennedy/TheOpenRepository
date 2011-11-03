use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name              => 'Perl::Dist::WiX::BuildPerl::5142',         #XXX-FIX-ON-VERSION-BUMP
	license                  => 'perl',
	dist_author              => 'KMX, kmx@cpan.org',
	dist_version_from        => 'lib/Perl/Dist/WiX/BuildPerl/5142.pm',      #XXX-FIX-ON-VERSION-BUMP
	create_readme            => 1,
	# Do not remove. Directories in t/ require it.
	recursive_test_files     => 1,
	requires => {
		'perl'              => '5.010',
		'Perl::Dist::WiX'   => '1.500',
		'Moose::Role'       => '2.00',
		'File::ShareDir'    => '1.02',
	},
	configure_requires => {
		'Module::Build'     => '0.36',
	},
	build_requires => {
		'Test::More'        => '0.88',
	},
	meta_merge => {
		resources => {
			repository  => 'http://svn.ali.as/cpan/trunk/Perl-Dist-WiX-BuildPerl-5142/',    #XXX-FIX-ON-VERSION-BUMP
		},
	},
	share_dir => {
		module => {
			'Perl::Dist::WiX::BuildPerl::5142'  => 'sharedir',      #XXX-FIX-ON-VERSION-BUMP
		}
	},
	add_to_cleanup      => [ 'Perl-Dist-WiX-BuildPerl-*', ],
);

$builder->create_build_script();
