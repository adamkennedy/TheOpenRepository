package Perl::Dist::WiX::Asset::Module;

use Moose;
use MooseX::Types::Moose qw( Str Bool ); 
use English qw( -no_match_vars ); 
use File::Spec::Functions qw( catdir );
require Perl::Dist::WiX::Exceptions;
require File::List::Object;
require IO::File;

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

with 'Perl::Dist::WiX::Role::Asset';

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_name',
	required => 1,
);

has force => (
	is       => 'ro',
	isa      => Bool,
	reader   => 'get_force',
	lazy     => 1,
	default  => sub { !! $_[0]->parent->force },
);

has packlist => (
	is       => 'ro',
	isa      => Bool,
	reader   => '_get_packlist',
	default  => 1,
);

# Don't know what these are for.
#use Object::Tiny qw{
#	type
#	extras
#};

sub install {
	my $self   = shift;
	my $name  = $self->_get_name();
	my $force = $self->_get_force();
		
	my $packlist_flag = $self->_get_packlist();

	unless ( $self->_get_bin_perl ) {
		PDWiX->throw(
			'Cannot install CPAN modules yet, perl is not installed');
	}
	my $dist_file = catfile( $self->_get_output_dir, 'cpan_distro.txt' );

	# Generate the CPAN installation script.
	# Fix url's for minicpans until 1.9403 is released.
	my $url = $self->_get_cpan()->as_string();
	$url =~ s{\Afile:///C:/}{file://C:/}msx;

	my $dp_dir = catdir( $self->_get_wix_dist_dir, 'distroprefs' );
	my $internet_available = ($url =~ m{ \A file://}msx) ? 1 : 0; 
	
	my $cpan_string = <<"END_PERL";
print "Loading CPAN...\\n";
use CPAN;
CPAN::HandleConfig->load unless \$CPAN::Config_loaded++;
\$CPAN::Config->{'urllist'} = [ '$url' ];
\$CPAN::Config->{'use_sqlite'} = q[0];
\$CPAN::Config->{'prefs_dir'} = q[$dp_dir];
\$CPAN::Config->{'prerequisites_policy'} = q[ignore];
\$CPAN::Config->{'connect_to_internet_ok'} = q[$internet_available];
print "Installing $name from CPAN...\\n";
my \$module = CPAN::Shell->expandany( "$name" ) 
	or die "CPAN.pm couldn't locate $name";
my \$dist_file = '$dist_file'; 
if ( \$module->uptodate ) {
	unlink \$dist_file;
	print "$name is up to date\\n";
	exit(0);
}
SCOPE: {
	open( CPAN_FILE, '>', \$dist_file )      or die "open: $!";
	print CPAN_FILE 
		\$module->distribution()->pretty_id() or die "print: $!";
	close( CPAN_FILE )                       or die "close: $!";
}

print "\\\$ENV{PATH} = '\$ENV{PATH}'\\n";
if ( $force ) {
	CPAN::Shell->notest('install', '$name');
} else {
	CPAN::Shell->install('$name');
}
print "Completed install of $name\\n";
unless ( \$module->uptodate ) {
	die "Installation of $name appears to have failed";
}
exit(0);
END_PERL

	my $filelist_sub;
	if ( not $self->_get_packlist() ) {
		$filelist_sub = File::List::Object->new->readdir(
			catdir( $self->image_dir, 'perl' ) );
		$self->_trace_line( 5,
			    "***** Module being installed $name"
			  . " requires packlist => 0 *****\n" );
	}

	# Dump the CPAN script to a temp file and execute
	$self->_trace_line( 1, "Running install of $name\n" );
	$self->_trace_line( 2, '  at ' . localtime() . "\n" );
	my $cpan_file = catfile( $self->_get_build_dir(), 'cpan_string.pl' );
  SCOPE: {
		my $CPAN_FILE;
		open $CPAN_FILE, '>', $cpan_file
		  or PDWiX->throw("CPAN script open failed: $!");
		print {$CPAN_FILE} $cpan_string
		  or PDWiX->throw("CPAN script print failed: $!");
		close $CPAN_FILE or PDWiX->throw("CPAN script close failed: $!");
	}
	local $ENV{PERL_MM_USE_DEFAULT} = 1;
	local $ENV{AUTOMATED_TESTING}   = undef;
	local $ENV{RELEASE_TESTING}     = undef;
	$self->_run3( $self->_get_bin_perl, $cpan_file )
	  or PDWiX->throw('CPAN script execution failed');
	PDWiX->throw(
		"Failure detected installing $name, stopping [$CHILD_ERROR]")
	  if $CHILD_ERROR;

	# Read in the dist file and return it as $dist_info.
	my @files;
	if ( -r $dist_file ) {
		my $fh = IO::File->new( $dist_file, 'r' );
		if ( not defined $fh ) {
			PDWiX->throw("CPAN modules file error: $!");
		}
		my $dist_info = <$fh>;
		$fh->close;
		$dist_info =~ s{\.tar\.gz}{}msx;   # Take off extensions.
		$dist_info =~ s{\.zip}{}msx;
		$dist_info =~ s{.+\/}{}msx;    # Take off directories.
		$self->_add_to_distributions_installed($dist_info);
	} else {
		$self->_trace_line( 0,
			"Distribution for module $name was up-to-date\n" );
	}

	# Making final filelist.
	my $filelist;
	if ($packlist_flag) {
		$filelist = $self->_search_packlist( $name );
	} else {
		$filelist = File::List::Object->new()->readdir(
			catdir( $self->image_dir, 'perl' ) );
		$filelist->subtract($filelist_sub)->filter( $self->_filters );
	}

	return $filelist;
} ## end sub install_module

1;
