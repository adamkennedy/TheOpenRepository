use inc::Module::Install 0.91;

die "OS unsupported\n" unless win32;

# Create README file.
if (0 && author_context) {
	print "Creating README file\n";
	require Pod::Readme;
	my $readme = Pod::Readme->new();
	$readme->parse_from_file('lib/Test/Perl/Dist.pm', 'README');
}

all_from       'lib/Test/Perl/Dist.pm';
requires       'Test::More'           => '0.61';
resources      'repository'           => 'http://svn.ali.as/cpan/trunk/Test-Perl-Dist/';
resources      'bugtracker'           => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Perl-Dist';
resources      'homepage'             => 'http://csjewell.comyr.com/perl/';
license        'perl';

WriteAll;
