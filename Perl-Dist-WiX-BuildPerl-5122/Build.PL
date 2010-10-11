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

    $self->test_files( qw( t xt/author ) );
    $self->depends_on('test');

    return;
}



sub ACTION_releasetest {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw( t xt/author xt/release ) );
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
    module_name              => 'Perl::Dist::WiX::BuildPerl::5122',
    license                  => 'perl',
    dist_author              => [ 'Curtis Jewell <CSJewell@cpan.org>' ],
    dist_version_from        => 'lib/Perl/Dist/WiX/BuildPerl/5122.pm',
	create_readme            => 1,
	create_license           => 1,
	requires => {
		'perl'              => '5.010',
		'Perl::Dist::WiX'   => '1.250_100',
		'Moose::Role'       => '1.08',
		'File::ShareDir'    => '1.02',
	},
	build_requires => {
		'Test::More'        => '0.88',
	},
	meta_merge => {
		resources => {
			homepage    => 'http://csjewell.comyr.com/perl/',
			bugtracker  => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX',
			repository  => 'http://svn.ali.as/cpan/trunk/Perl-Dist-WiX-BuildPerl-5122/',
			IRC         => 'irc://irc.perl.org/#win32',
		},
	},
	share_dir => {
		module => {
			'Perl::Dist::WiX::BuildPerl::5122'  => 'share',
		}
	},
    add_to_cleanup      => [ 'Perl-Dist-WiX-BuildPerl-5122-*', ],
);

$builder->create_build_script();
