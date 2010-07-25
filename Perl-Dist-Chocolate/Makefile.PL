use inc::Module::Install 1.00;

die "OS unsupported\n" unless win32;

# Create README file.
if (author_context) {
	print "Creating README file\n";
	require Pod::Readme;
	my $readme = Pod::Readme->new();
	$readme->parse_from_file('lib/Perl/Dist/Chocolate.pm', 'README');
}

all_from      'lib/Perl/Dist/Chocolate.pm';
# Really, 2.10_11, but I can't do that.
requires      'Perl::Dist::Strawberry' => '2.10';
# Really, 1.200_102, but I can't do that, either.
requires      'Perl::Dist::WiX'        => '1.200';
requires      'parent'                 => '0.221';
requires      'URI::file'              => '4.20'; # From URI 1.36 or better.
test_requires 'Test::More'             => '0.42';
test_requires 'LWP::Online'            => '1.07';
test_requires 'Test::Perl::Dist'       => '0.203';
resources     'repository'             => 'http://svn.ali.as/cpan/trunk/Perl-Dist-Chocolate';
resources     'bugtracker'             => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Chocolate';
resources     'homepage'               => 'http://www.strawberryperl.com/';
resources     'IRC'                    => 'irc://irc.perl.org/#win32';
resources     'WebIRC'                 => 'http://widget.mibbit.com/?server=irc.perl.org&channel=%23win32';
# Requires Module::Install::AutoLicense on the author end.
auto_license;
use_ptar;
install_share;

WriteAll;
