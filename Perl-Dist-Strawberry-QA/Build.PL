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
	module_name        => 'Perl::Dist::Strawberry::QA',
	license            => 'perl',
	dist_author        => 'Curtis Jewell <csjewell@cpan.org>',
	dist_version_from  => 'lib/Perl/Dist/Strawberry/QA.pm',
	create_readme      => 1,
	create_license     => 1,
	requires           => {
		'perl'               => '5.012',
		'File::List::Object' => '0.189', 
		'Archive::Extract'   => 0,
		'File::Temp'         => 0,
		'File::HomeDir'      => 0,
		'IPC::Run3'          => 0,		
	},
	build_requires     => {
		'Test::More'   => '0.88',
		'Test::Script' => '1.07',
	},
	meta_merge => {
		resources => {
			homepage   => 'http://csjewell.comyr.com/perl/',
			bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Dist-Strawberry-QA',
			repository => 'http://svn.ali.as/cpan/trunk/Perl-Dist-Strawberry-QA'
		},
	},
	add_to_cleanup => [ 'Perl-Dist-Strawberry-QA-*', ],
);

$builder->create_build_script();
