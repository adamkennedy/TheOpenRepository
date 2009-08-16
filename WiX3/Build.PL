use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WiX3',
    license             => 'perl',
    dist_author         => 'Curtis Jewell <csjewell@cpan.org>',
    dist_version_from   => 'lib/WiX3.pm',
	create_makefile_pl  => 'passthrough',
	create_license      => 1,
	create_readme       => 1,
	configure_requires => {
		'Module::Build'            => '0.33',
	},
	build_requires => {
		'Test::More'               => '0.61',
		'Test::UseAllModules'      => '0.12',
	},
    requires => {
		'perl'                     => 5.008001,
		'Exception::Class'         => '1.29',
		'List::MoreUtils'          => '>= 0.22, != 0.23, != 0.24',
		'Data::UUID'               => '1.202',
		'Params::Util'             => '1.00',
		'Moose'                    => '0.86',
		'MooseX::LogDispatch'      => '1.2000',
		'MooseX::Singleton'        => '0.19',
		'MooseX::Types'            => '0.16',
		'MooseX::Types::Moose'     => 0,
		'MooseX::AttributeHelpers' => '0.19',
		'MooseX::NonMoose'         => '0.05',
		'Regexp::Common'           => '2.122',
        'version'                  => '0.77',
		'Readonly'                 => '1.03',
    },
	recommends => {
		'MIME::Lite'               => '3.020',
		'Readonly::XS'             => '1.05',
	},
	meta_merge     => {
        resources => {
            homepage    => 'http://csjewell.comyr.com/perl/',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=WiX3',
            repository  => 'http://svn.ali.as/cpan/trunk/WiX3/'
        },
	},
    add_to_cleanup      => [ 'WiX3-*' ],
);

$builder->create_build_script();
