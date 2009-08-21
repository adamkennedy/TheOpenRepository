package Perl::Dist::WiX::Role::Asset;

# Convenience role for Perl::Dist::WiX assets

use 5.008001;
use Moose;
# TODO: Throw exceptions instead.
use Carp             qw(croak);
use File::Spec::Unix qw();
use File::ShareDir   qw();
use URI              qw();
use URI::file        qw();
use File::Spec::Functions qw( rel2abs )
use MooseX::Types::Moose qw( Str );
use File::List::Object qw();

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

has parent => (
	is       => 'ro',
	isa      => 'Perl::Dist::WiX',
	reader   => 'get_parent',
	required => 1,
);

has url => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_url',
	required => 1,
);

has file => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_file',
	required => 1,
);

# An asset knows how to install itself.
requires 'install';

#####################################################################
# Mangle arguments for constructor.

sub BUILDARGS {
	my $class = shift;
	my %args;
	
	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{$_[0]};
	} elsif ( 0 == @_ % 2 ) {
		%args = ( @_ );
	} else {
		print "Error situation 1\n";
		# TODO: Throw an error.
	}

	unless ( defined $args{url} ) {
		if ( defined $args{share} ) {
			# Map share to url vis File::ShareDir
			my ($dist, $name) = split /\s+/, $args{share};
			$self->trace("Finding $name in $dist... ");
			my $file = rel2abs(
				File::ShareDir::dist_file( $dist, $name )
			);
			unless ( -f $file ) {
				# TODO: Throw exception instead.
				croak("Failed to find $file");
			}
			$args{url} = URI::file->new($file)->as_string;
			$self->trace(" found\n");

		} elsif ( defined $args{dist} ) {
			# Map CPAN dist path to url
			my $dist = $args{dist};
			$self->trace("Using distribution path $dist\n");
			my $one  = substr( $dist, 0, 1 );
			my $two  = substr( $dist, 1, 1 );
			my $path = File::Spec::Unix->catfile(
				'authors', 'id', $one, "$one$two", $dist,
			);
			$args{url} = URI->new_abs( $path, $args{parent}->cpan )->as_string;

		} elsif ( defined $args{name} ) {
			# Map name to URL via the default package path
			$args{url} = $self->parent->binary_url($args{name});
		}
	}

	# Create the filename from the url
	$args{file} = $args{url};
	$args{file} =~ s|.+/||;
	unless ( defined $args{file} and length $args->{file} ) {
		# TODO: Throw exception
		croak("Missing or invalid file");
	}

	my %default_args = url => ( $args{url}, file => $args{file}, parent => $args{parent} );
	delete @args{'url', 'file', 'parent', 'name', 'share', 'dist'}
	
	return { (%default_args) , (%args) };
}

sub cpan {
	# Throw error.
}

sub _search_packlist {
	my ( $self, $module ) = @_;

	my $parent = $self->_get_parent();
	
	# We don't use the error until later, if needed.
	my $error = <<"EOF";
No .packlist found for $module.

Please set packlist => 0 when calling install_distribution or 
install_module for this module.  If this is in an install_modules 
list, please take it out of the list, creating two lists if need 
be, and create an install_module call for this module with 
packlist => 0.
EOF
	chomp $error;

	my @module_dirs = split /::/ms, $module;
	my @dirs = (
		catdir( $parent->image_dir, qw{perl vendor lib auto}, @module_dirs),
		catdir( $parent->image_dir, qw{perl site   lib auto}, @module_dirs),
		catdir( $parent->image_dir, qw{perl        lib auto}, @module_dirs),
	);

	my $packlist;
  DIR:
	foreach my $dir (@dirs) {
		$packlist = catfile($dir, '.packlist')
		last DIR if -r $packlist; 
	}

	if ( -r $packlist ) {
		$fl = File::List::Object->new->load_file($packlist)->add_file($packlist);
	} else {

		my $output = catfile( $parent->output_dir, 'debug.out' );
		
		# Trying to use the output to make an array.
		$parent->trace_line( 3,
			"Attempting to use debug.out file to make filelist\n" );

		my $fh = IO::File->new( $output, 'r' );
		if ( not defined $fh ) {
			PDWiX->throw("Error reading output file $output: $!");
		}
		my @output_list = <$fh>;
		$fh->close();

		my @files_list =
		  map { ## no critic 'ProhibitComplexMappings'
			my $t = $_;
			chomp $t;
			( $t =~ / \A Installing [ ] (.*) \z /msx ) ? ($1) : ();
		  } @output_list;

		if ( $#files_list == 0 ) {
			PDWiX->throw($error);
		} else {
			$parent->trace_line( 4, "Adding files:\n" );
			$parent->trace_line( 4, q{  } . join "\n  ", @files_list );
			$fl = File::List::Object->new->load_array(@files_list);
		}
	} ## end else [ if ( -r $perl ) ]

	return $fl->filter( $parent->filters );
} ## end sub search_packlist


1;
