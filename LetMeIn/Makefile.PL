use inc::Module::Install 0.76;
use strict;

all_from       'lib/LetMeIn.pm';
requires       'Carp'                 => 0;
requires       'FindBin'              => 0;
requires       'File::Spec'           => '0.80';
requires       'Scalar::Util'         => '1.15';
requires       'CGI'                  => '3.00';
requires       'CGI::Cookie'          => 0;
requires       'YAML::Tiny'           => '1.12';
requires       'Authen::Htpasswd'     => '0.15';
requires       'Email::MIME'          => '1.859';
requires       'Email::MIME::Creator' => '1.453';
requires       'Email::Send'          => '2.182';
requires       'Module::CGI::Install' => '0.04';
test_requires  'Test::More'           => '0.42';
test_requires  'IPC::Run3'            => '0.034';
test_requires  'File::Copy'           => 0;
test_requires  'File::Remove'         => '0.37';
install_script 'letmein.pl';

# Generate the script
print "Generating script/letmein...\n";
if ( generate_script() ) {
	install_script 'letmein';
}

clean_files    'script/letmein';

WriteAll;
exit(0);





#####################################################################
# Support Functions

# Merge letmein.pl and LetMeIn.pm to create the final 'letmein' script
sub generate_script {
	$INC{'File/Spec.pm'} or return 0;

	my $pl  = File::Spec->catfile( 'script', 'letmein.pl' );
	my $pm  = File::Spec->catfile( 'lib',    'LetMeIn.pm' );
	my $out = File::Spec->catfile( 'script', 'letmein'    );

	# Read in the .pl file
	open( READPL, $pl )   or die "open: $!";
	my $readpl = do { local $/; <READPL> } or die "read: $!";
	close( READPL )       or die "close: $!";

	# Read in the .pm file
	open( READPM, $pm )   or die "open: $!";
	my $readpm = do { local $/; <READPM> } or die "read: $!";
	close( READPM )       or die "close: $!";

	# Put the .pm file into the .pl file;
	$readpl =~ s/\n\.\.\.\n/\n$readpm...\n/
		or die "LetMeIn.pm insertion into script failed";

	# Write out the combined script
	open( WRITEOUT, ">$out" ) or die "open: $!";
	print WRITEOUT $readpl    or die "write: #!";

	return 1;
}
