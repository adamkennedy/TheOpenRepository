use inc::latest Module::Build;

print <<'EOF';
To install the true prerequisites, you may wish to run

	cpan ANDK/CPAN-1.94_53.tar.gz

or their equivalents before running this, if you haven't 
(or haven't installed later versions) already.

If you're already in CPAN or CPANPLUS, replace 'cpan' with 'install'.
If you're in CPAN, 'reload cpan' afterwards.

EOF

require CPAN;
die "Please upgrade CPAN as instructed above.\n\n" unless $CPAN::VERSION > 1.9452;

die "OS unsupported\n" unless 'MSWin32' eq $^O;

# These are the main requirements.
my $requires = {
	'parent'                    => '0.221',
	'Alien::WiX'                => '0.300000',
	'Archive::Tar'              => '1.42',
	'Archive::Zip'              => '1.26',
	'CPAN'                      => '1.9452',
	'Data::Dump::Streamer'      => '2.08',
	'Data::UUID'                => '1.149',
	'Devel::StackTrace'         => '1.20',
	'Exception::Class'          => '1.22',
	'File::Copy::Recursive'     => '0.38',
	'File::Find::Rule'          => '0.30',
	'File::HomeDir'             => '0.82',
	'File::List::Object'        => '0.201',
	'File::Path'                => '2.07',
	'File::PathList'            => '1.04',
	'File::pushd'               => '1.00',
	'File::Remove'              => '1.42',
	'File::ShareDir'            => '1.00',
	'File::Spec'                => '3.29',
	'File::Temp'                => '0.21',
	'HTTP::Status'              => '5.817',
	'IPC::Run3'                 => '0.042',
	'IO::Capture'               => '0.05',
	'IO::String'                => '1.08',
	'List::MoreUtils'           => '0.07',
	'LWP::UserAgent'            => '5.823',
	'LWP::UserAgent::WithCache' => '0.06',
	'LWP::Online'               => '1.07',
	'Module::CoreList'          => '2.18',
	'Moose'                     => '0.90',
	'MooseX::NonMoose'          => '0.05',
	'PAR::Dist'                 => '0.42',
	'Params::Util'              => '0.35',
	'Portable::Dist'            => '0.04',
	'Probe::Perl'               => '0.01',
	'Process'                   => '0.26',
	'Readonly'                  => '1.03',
	'Template'                  => '>= 2.20, != 2.21',
	'URI'                       => '1.35',
	'WiX3'                      => '0.008',
	'YAML::Tiny'                => '1.36',
	'Win32'                     => '0.35',
	'Win32::Exe'                => '0.11',
	'Win32::File::Object'       => '0.01',
	'Win32API::File'            => '0.1001',
};

my $builder = Module::Build->new(
	module_name         => 'Perl::Dist::WiX',
	license             => 'perl',
	dist_author         => 'Curtis Jewell <csjewell@cpan.org>',
	dist_version_from   => 'lib/Perl/Dist/WiX.pm',
	create_makefile_pl  => 'passthrough',
	create_license      => 1,
	create_readme       => 1,
# Will do this soon, but I have to get a key first.
#	sign                => 1,
	configure_requires => {
		'Module::Build'             => '0.36',
		'CPAN'                      => '1.9453',
	},
	requires => $requires,
	build_requires => {
		'Test::LongString'          => '0.11',
		'Test::More'                => '0.86',
		'Test::Output'              => '0.11',
		'Test::Perl::Dist'          => '0.202',
		'Test::Script'              => '1.03',
		'Test::UseAllModules'       => '0.09',
	},
	recommends => {
		'Readonly::XS'              => '1.05',
	},
	meta_merge     => {
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

$builder->create_build_script();
