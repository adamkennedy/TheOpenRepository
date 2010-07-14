use inc::latest Module::Build;

# To make sure these get into the inc\ directory for our M::B subclass.
# use inc::latest CPAN::Meta;
# use inc::latest Version::Requirements;
# use inc::latest JSON;
# These two will be removed when 5.10.1 becomes our perl requirement after July 2010 is released.
# use inc::latest Parse::CPAN::Meta;
# use inc::latest autodie;

# CPAN version test.
require CPAN;
if ($CPAN::VERSION < 1.9457) {
	print <<'EOF';
To install the rest of the prerequisites, you need to run

	cpan ANDK/CPAN-1.94_58.tar.gz

before installing this. 

If you're already in CPAN or CPANPLUS, replace 'cpan' with 'install'.
If you're in CPAN, 'reload cpan' afterwards.

EOF
	die "Please upgrade CPAN as instructed above.\n\n";
}

die "OS unsupported\n" unless 'MSWin32' eq $^O;

# These are the main requirements.
my $requires = {
	'perl'                       => '5.008001',
	'parent'                     => '0.221',
	'Alien::WiX'                 => '0.300000',
	'Archive::Tar'               => '1.42',
	'Archive::Zip'               => '1.26',
	'CPAN'                       => '1.9457',
	'Clone'                      => '0.31',
	'Data::Dump::Streamer'       => '2.08',
	'Data::UUID'                 => '1.149',
	'Digest::CRC'                => '0.14',
	'Devel::StackTrace'          => '1.20',
	'Exception::Class'           => '1.22',
	'File::Copy::Recursive'      => '0.38',
	'File::Find::Rule'           => '0.30',
	'File::HomeDir'              => '0.82',
	'File::List::Object'         => '0.201',
	'File::Path'                 => '2.07',
	'File::PathList'             => '1.04',
	'File::pushd'                => '1.00',
	'File::Remove'               => '1.42',
	'File::ShareDir'             => '1.00',
	'File::Spec'                 => '3.29',
	'File::Temp'                 => '0.21',
	'HTTP::Status'               => '5.817',
	'IPC::Run3'                  => '0.042',
	'IO::Capture'                => '0.05',
	'IO::Compress::Bzip2'        => '2.025',
	'IO::String'                 => '1.08',
	'List::MoreUtils'            => '0.07',
	'LWP::UserAgent'             => '5.823',
	'LWP::UserAgent::WithCache'  => '0.06',
	'LWP::Online'                => '1.07',
	'Module::CoreList'           => '2.32',
	'Moose'                      => '0.90',
	'MooseX::NonMoose'           => '0.05',
	'MooseX::Singleton'          => '0',
	'MooseX::Types'              => '0',
	'MooseX::Types::URI'         => '0.02',
	'MooseX::Types::Path::Class' => '0.05',
	'namespace::autoclean'       => '0.10',
	'PAR::Dist'                  => '0.42',
	'Params::Util'               => '0.35',
	'Portable::Dist'             => '0.03',
	'Probe::Perl'                => '0.01',
	'Process'                    => '0.26',
	'Readonly'                   => '1.03',
	# Template 2.21 will not install on Windows, anyway.
	'Template'                   => '2.22',
	'URI'                        => '1.35',
	'WiX3'                       => '0.009100',
	'YAML::Tiny'                 => '1.36',
	'Win32'                      => '0.35',
	'Win32::Exe'                 => '0.13',
	'Win32::File::Object'        => '0.01',
	'Win32API::File'             => '0.1001',
};

my $class = Module::Build->subclass(
	class => 'PDWiX::Builder',
	code  => <<'END_CODE',
# use inc::latest CPAN::Meta;
# use inc::latest Version::Requirements;
# use inc::latest JSON;
# These two will be removed when 5.10.1 becomes our perl requirement after July 2010 is released.
# use inc::latest Parse::CPAN::Meta;
# use inc::latest autodie;

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

    $self->test_files( qw< t xt/author rt > );
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

# sub read_metafile {
#  my $self = shift;
#  my ($metafile) = @_;
#
#  my $meta = CPAN::Meta->new($metafile);
#
#  return $meta;
#}

# This is called by ACTION_distmeta
#sub write_metafile {
#  my $self = shift;
#  my ($metafile, $node) = @_;
#
#  my $meta = CPAN::Meta->new($node);
#  return $meta->save($metafile);
#}

END_CODE
);


my $builder = $class->new(
	module_name         => 'Perl::Dist::WiX',
	license             => 'perl',
	dist_author         => 'Curtis Jewell <csjewell@cpan.org>',
	dist_version_from   => 'lib/Perl/Dist/WiX.pm',
	create_makefile_pl  => 'small',
	create_license      => 1,
	create_readme       => 1,
# Will do this soon, but I have to get a key first.
#	sign                => 1,
	configure_requires => {
		'Module::Build'             => '0.36',
		'CPAN'                      => '1.9457',
	},
	requires => $requires,
	build_requires => {
		'Test::LongString'          => '0.11',
		'Test::More'                => '0.86',
		'Test::Output'              => '0.11',
		'Test::Perl::Dist'          => '0.300',
		'Test::Script'              => '1.03',
		'Test::UseAllModules'       => '0.09',
	},
	recommends => {
		# To speed up scalar Readonly variables.
		'Readonly::XS'              => '1.05',
		# To notify Growl for Windows.
		'Growl::GNTP'               => '0.07',
		# To extract .xz files.
		'IO::Compress::Xz'          => '2.025'
	},
	meta_add => {
		no_index => {
			directory => [qw(inc share t)],
		},
	}, 
	meta_merge => {
		resources => {
			homepage    => 'http://csjewell.comyr.com/perl/',
			bugtracker  => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX',
			repository  => 'http://svn.ali.as/cpan/trunk/Perl-Dist-WiX/',
			IRC         => 'irc://irc.perl.org/#win32',
		},
	},
	share_dir => {
		dist => 'share',
	},
	script_files => [
		'script/perldist_w'
	],
);
# $builder->metafile('META.json');
# $builder->mymetafile('MYMETA.json');

# To support our 899_prereq test, we have to wrap this.
unless ('Test::Prereq::Build' eq ref $builder) {
	my $answer = $builder->y_n('Do you want to install the minimal minicpan script?', 'n');

	if ($answer) {
		$builder->script_files(['script\minicpan_pdwix', 'script\perldist_w']);
		$builder->requires({
			'CPAN::Mini'        => '0.576',
			'CPAN::Mini::Devel' => '0.03',
			'File::Slurp'       => '9999.13',
			( %{$requires} )
		});
	}
}

$builder->create_build_script();
