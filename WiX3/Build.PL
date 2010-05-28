use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
	class => 'My::Builder',
	code  => <<'END_CODE',
sub ACTION_authortest {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw< t xt/author > );
    $self->depends_on('test');

    return;
}


sub ACTION_releasetest {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw< t xt/author xt/release > );
    $self->depends_on('test');

    return;
}


sub ACTION_manifest {
    my ($self, @arguments) = @_;

    if (-e 'MANIFEST') {
        unlink 'MANIFEST' or die "Can't unlink MANIFEST: $!";
    }

    return $self->SUPER::ACTION_manifest(@arguments);
}
END_CODE
);


my $builder = $class->new(
	module_name          => 'WiX3',
	license              => 'perl',
	dist_author          => 'Curtis Jewell <csjewell@cpan.org>',
	dist_version_from    => 'lib/WiX3.pm',
	create_makefile_pl   => 'small',
	create_license       => 1,
	create_readme        => 1,
	recursive_test_files => 1,
	configure_requires => {
		'Module::Build'            => '0.33',
	},
	build_requires => {
		'Test::More'               => '0.61',
		'Test::UseAllModules'      => '0.12',
	},
	requires => {
		'perl'                     => 5.008001,
		'parent'                   => '0.221',
		'Exception::Class'         => '1.29',
		'List::MoreUtils'          => '>= 0.22, != 0.23, != 0.24',
		'Data::UUID'               => '1.202',
		'Params::Util'             => '1.00',
		'Moose'                    => '0.90',
		'MooseX::Singleton'        => '0.21',
		'MooseX::Types'            => '0.20',
		'MooseX::Types::Moose'     => 0,
		'Regexp::Common'           => '2.122',
		'Readonly'                 => '1.03',
	},
	recommends => {
		'Readonly::XS'             => '1.05',
	},
	meta_merge     => {
		resources => {
			homepage    => 'http://csjewell.comyr.com/perl/',
			bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=WiX3',
			repository  => 'http://svn.ali.as/cpan/trunk/WiX3/',
		},
	},
	add_to_cleanup      => [ 'WiX3-*' ],
);

$builder->create_build_script();
