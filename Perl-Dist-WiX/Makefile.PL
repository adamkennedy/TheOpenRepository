use inc::Module::Install 0.91;

die "OS unsupported\n" unless win32;

# Create README file.
if (author_context) {
	print "Creating README file\n";
	require Pod::Readme;
	my $readme = Pod::Readme->new();
	$readme->parse_from_file('lib/Perl/Dist/WiX.pm', 'README');
}

# Cheat to make sure that the module that
# includes install_script is always
# copied into the distribution.
if (is_admin) {
	admin()->load('install_script', 1);
}

all_from       'lib/Perl/Dist/WiX.pm';
requires       'parent'               => '0.221';
requires       'Alien::WiX'           => '0.300000';
requires       'Data::Dump::Streamer' => '2.08';
requires       'Data::UUID'           => '1.149';
requires       'Devel::StackTrace'    => '1.20';
requires       'Exception::Class'     => '1.22';
requires       'File::ShareDir'       => '1.00';
requires       'File::List::Object'   => '0.189';
requires       'IO::String'           => '1.08';
requires       'List::MoreUtils'      => '0.07';
requires       'Module::CoreList'     => '2.18';
requires       'Process'              => '0.26';
requires       'Readonly'             => '1.03';
requires       'URI'                  => '1.35';
requires       'WiX3'                 => '0.006';
recommends     'Readonly::XS'         => '1.05';
test_requires  'Test::More'           => '0.61';
test_requires  'Test::Output'         => '0.11';
test_requires  'Test::UseAllModules'  => '0.09';
requires       'Win32'                => '0.35';
requires       'Win32::Exe'           => '0.11';
requires       'Win32API::File'       => '0.1001';
resources      'repository'           => 'http://svn.ali.as/cpan/trunk/Perl-Dist-WiX/';
resources      'bugtracker'           => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX';
resources      'homepage'             => 'http://csjewell.comyr.com/perl/';
resources      'IRC'                  => 'irc://irc.perl.org/#win32';
resources      'DLSIP'                => 'http://search.cpan.org/dlsip?RpdOp';
license        'perl';
install_share;

my $answer;
YN: 
  while ($answer = prompt 'Do you want to install the minimal minicpan script?', 'n') {
	last YN if $answer =~ /^y/i;
	last YN if $answer =~ /^n/i;
	local $| = 1;
	print "Please answer 'y' or 'n'.\n";
}

if ($answer =~ /^y/i) {
	require File::Spec;
	my $script_file = File::Spec->catfile('script', 'minicpan_pdwix'); 
	install_script  $script_file;
	requires       'CPAN::Mini'        => '0.576';
	requires       'CPAN::Mini::Devel' => '0.03';
	requires       'File::Slurp'       => '9999.13';
}

WriteAll;
