#!perl

use strict;
use warnings;
use local::lib 1.004007 qw();
# use IO::Prompt; # I would use this if it worked.
use IO::Interactive qw(is_interactive);
use File::HomeDir 0.81;
use File::Spec::Functions 3.2701 qw(splitpath catpath);

my $users_key;
use Win32::TieRegistry 0.26 (
	TiedRef => \$users_key, Delimiter => '/', FastDelete => 1, ArrayValues => 0);

if (!is_interactive()) {
	die "llw32helper must be run interactively."
}

my $environment_key = $users_key->{'Environment/'};

local $ENV{HOME} = undef;

my $ll_exists = 0;
my $default_path;
if (exists $environment_key->{'MODULEBUILDRC'}) {
	$ll_exists = 1;
	my ($volume,$directories,$file) = File::Spec->splitpath( $environment_key->{'MODULEBUILDRC'} );
	$default_path = catpath($volume, $directories, undef);
} else {
	$default_path = catdir(Win32::GetShortPathName(File::HomeDir->my_home()), 'perl5');
}

if ($ll_exists) {
  EXISTS:
	print "Do you wish to remove the local::lib settings from $default_path? [y/N] ";

	my $answer = <STDIN>;
    chomp $answer if defined $answer;

	$answer = 'n' if $answer eq q{};

	if ('n' eq lc substr $answer, 1 ) {
		print "llwin32helper exiting.\n";
		exit;
	}
	
	goto EXISTS if ('y' ne lc substr $answer, 1 );

	print 'Would remove at this point.';
	exit;
	
	delete $environment_key->{'MODULEBUILDRC'};
	delete $environment_key->{'PERL_MM_OPT'};
	delete $environment_key->{'PERL5LIB'};
	
	# Fix the path.

} else {
  NOTEXISTS:
	print "Do you wish to install future modules in a local area? [y/N] ";

	my $answer = <STDIN>;
    chomp $answer if defined $answer;

	$answer = 'n' if $answer eq q{};

	if ('n' eq lc substr $answer, 1 ) {
		print "llwin32helper exiting.\n";
		exit;
	}
	
	goto NOTEXISTS if ('y' ne lc substr $answer, 1 );

  PATH:
	print "Where do you want to install modules? [$default_path] ";	

	$answer = <STDIN>;
    chomp $answer if defined $answer;

	$answer = $default_path if $answer eq q{};
	
	if (! -d $answer) {
		print "Path input does not exist.";
		goto PATH;
	}
	
	my %ll_env_entries = local::lib->build_environment_vars_for($answer, 0);
	
	$environment_key->{'MODULEBUILDRC'} = $ll_env_entries{'MODULEBUILDRC'};
	$environment_key->{'PERL_MM_OPT'} = $ll_env_entries{'PERL_MM_OPT'};
	$environment_key->{'PERL5LIB'} = $ll_env_entries{'PERL5LIB'};
	
	if (exists $environment_key->{'PATH'}) {
		$environment_key->{'PATH'} = join ';', 
			local::lib->install_base_bin_path($answer),
			$environment_key->{'PATH'};
	} else {
		$environment_key->{'PATH'} = local::lib->install_base_bin_path($answer);	
	}
	
	local::lib->ensure_dir_structure_for($answer);
	
	print <<"__END_TEXT__";
llwin32helper has added environment entries added so that CPAN/CPANPLUS installs future modules
to $answer.

To use modules installed this way in your scripts, insert this line:
     use local::lib '~\\perl5'; 
(if you changed the directory, use that directory instead.)

To remove these environment entries, run llw32helper again.
__END_TEXT__

	exit;
}
