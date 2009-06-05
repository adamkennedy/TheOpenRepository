package File::List::Object;

=pod

=begin readme text

File::List::Object version 0.185

=end readme

=for readme stop

=head1 NAME

File::List::Object - Object containing a list of files (filelist, packlist).

=head1 VERSION

This document describes File::List::Object version 0.185.

=for readme continue

=head1 DESCRIPTION

This package provides for creating a list of files (from different sources) 
and performing arithmetic and other applicable operations on said lists.

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

This method of installation will install a current version of Module::Build 
if it is not already installed.
    
Alternatively, to install with Module::Build, you can use the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=end readme

=for readme stop

=head1 SYNOPSIS

	# Since this module is object-oriented, it does not matter if you
	# use or require the module, because there are no imports.
	require File::List::Object;

	# Cheate a File::List::Object
	my $filelist = File::List::Object->new();

	# Clones the filelist passed in;
	$filelist3 = File::List::Object->clone($filelist);

	# Add an individual file to a filelist.
	$filelist->add_file('/usr/bin/perl5'); 

	# Load a filelist from an array of files.
	$filelist2 = File::List::Object->new();
	$filelist2->load_array(@files);

	# Adds the files in $filelist2 to $filelist
	$filelist->add($filelist2);

	# Subtracts the files in $filelist2 from $filelist
	$filelist->subtract($filelist2);

	# Filters out the files with these strings at the
	# beginnning of their name.
	$filelist->filter(['/excluded', '/bad']);

	# Filters out the files on drive D.
	$filelist->filter(['D:\']);

	# Gets the number of files in the list.
	$filelist->count();

	# Moves a file within the filelist.
	$filelist->move('file.txt', 'file2.txt');

	# Moves a directory within the filelist.
	$filelist->move_dir('\test1', '\test2');

	# Loads the filelist from a file with filenames in it.
    $filelist->load_file($packlist_file);

	# Returns the list of files, sorted.
	# Useful for debugging purposes.
	$filelist->as_string();

	# Most operations return the original object, so they can be chained.
	# count and as_string stop a chain, new and clone can only start one.
	$filelist->load_file($packlist_file)->add_file($file)->as_string();

=head1 DESCRIPTION

This module provides an object-oriented interface to manipulate a list of files.

It was made to manipulate Perl .packlist files in memory, but the filelist does not 
have to be loaded from disk.

=head1 INTERFACE

=cut

#<<<
use 5.008001;
use Moose;
use MooseX::AttributeHelpers;
use File::Spec::Functions
  qw( catdir catfile splitpath splitdir curdir updir     );
use vars           qw( $VERSION                          );
use Params::Util   qw( _INSTANCE _STRING _NONNEGINT      );
use IO::Dir        qw();
use IO::File       qw();
use Exception::Class (
	'File::List::Object::Exception' => {
		'description' => 'File::List::Object error',
	},
	'File::List::Object::Exception::Parameter' => {
		'description' =>
		  'File::List::Object error: Parameter missing or invalid',
		'isa'    => 'File::List::Object::Exception',
		'fields' => [ 'parameter', 'where' ],
	},
);

use version; $VERSION = version->new('0.185')->numify;

my %sortcache; # Defined at this level so that the cache does not
			   # get reset each time _sorter is called.
#>>>

# The only attribute of this object.

has '_files' => (
	metaclass => 'Collection::Hash',
    is  => 'rw',
    isa => 'HashRef[Str]',
	provides => {
		set => '_add_file',
		clear => '_clear',
		count => 'count',
		get => '_get_file',
		exists => '_is_file',
		delete => '_delete_files',
		keys => '_get_files_array',
		kv => '_get_files_kv',
	},
	reader => '_get_files_hashref',
	writer => '_set_files_hashref',
	init_arg => undef,
	default => sub { return {}; },
);

#####################################################################
# Construction Methods

=head2 new

	$filelist = File::List::Object->new();

Creates an empty object. To load the object with files, call add_file, 
load_array, or load_packlist.

=head2 clone

	$filelist2 = File::List::Object->clone($filelist);

Creates a new object that is a copy of the one passed to it.  It performs 
a deep copy, so that the original object is not modified when the new one 
is.

=cut

sub clone {
	my $self      = shift->new();
	my $source    = shift;

	# Check parameters
	if (not _INSTANCE( $source, 'File::List::Object' ) ) {
		File::List::Object::Exception::Parameter->throw(
			parameter => 'source',
			where     => '->clone'
		);
	}

	# Add filelist passed in.
	$self->_set_files_hashref({ $source->_get_files_kv() });

	return $self;
} ## end sub clone

#####################################################################
# Sorting filelists.

sub _splitdir {
	my $dirs = shift;

	my @dirs = splitdir($dirs);

	@dirs = grep { defined $_ and $_ ne q{} } @dirs;

	return \@dirs;
}

sub _splitpath {
	my $path = shift;

	my @answer = splitpath( $path, 0 );

	return \@answer;
}

sub _sorter {

# Takes advantage of $a and $b, using the Orcish Manoevure to cache
# calls to File::Spec::Functions::splitpath and splitdir

	# Short-circuit.
	return 0 if ( $a eq $b );

	# Get directoryspec and file
	my ( undef, $dirspec_1, $file_1 ) =
	  @{ ( $sortcache{$a} ||= _splitpath($a) ) };
	my ( undef, $dirspec_2, $file_2 ) =
	  @{ ( $sortcache{$b} ||= _splitpath($b) ) };

	# Deal with equal directories by comparing their files.
	return ( $file_1 cmp $file_2 ) if ( $dirspec_1 eq $dirspec_2 );

	# Get list of directories.
	my @dirs_1 = @{ ( $sortcache{$dirspec_1} ||= _splitdir($dirspec_1) ) };
	my @dirs_2 = @{ ( $sortcache{$dirspec_2} ||= _splitdir($dirspec_2) ) };

	# Find first directory that is not equal.
	my ( $dir_1, $dir_2 ) = ( q{}, q{} );
	while ( $dir_1 eq $dir_2 ) {
		$dir_1 = shift @dirs_1 || q{};
		$dir_2 = shift @dirs_2 || q{};
	}

	# Compare directories/
	return 1  if $dir_1 eq q{};
	return -1 if $dir_2 eq q{};
	return $dir_1 cmp $dir_2;
} ## end sub _sorter

#####################################################################
# Exception output methods.

sub File::List::Object::Exception::full_message { ## no critic 'Capitalization'
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->message() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";

	$string .= "\n" . $self->trace() . "\n";

	return $string;
} ## end sub File::List::Object::Exception::full_message

sub File::List::Object::Exception::Parameter::full_message { ## no critic 'Capitalization'
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->parameter()
	  . ' in File::List::Object'
	  . $self->where() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";

	# Add trace to it. (We automatically dump trace for parameter errors.)
	$string .= "\n" . $self->trace() . "\n";

	return $string;
} ## end sub File::List::Object::Exception::Parameter::full_message

#####################################################################
# Main Methods

=head2 count

	$number = $filelist->count();

Returns the number of files in the list.

=head2 clear

	$filelist = $filelist->clear();

Empties an object. 

=cut

sub clear {
	my $self = shift;

	$self->_clear();
	return $self;
}

=head2 files

	@filelist = $filelist->files();

Returns a sorted list of the files in this object. 

=cut

sub files {
	my $self = shift;

	my @answer = sort {_sorter} $self->_get_files_array();
	return \@answer;
}

=head2 readdir

	$filelist = $filelist->readdir('C:\');

Adds the files in the directory passed in to the filelist.

This includes all files within subdirectories of this directory.

=cut

sub readdir { ## no critic 'ProhibitBuiltinHomonyms'
	my ( $self, $dir ) = @_;

	# Check parameters.
	if ( not _STRING($dir) ) {
		File::List::Object::Exception::Parameter->throw(
			parameter => 'dir',
			where     => '->readdir'
		);
	}
	if (not -d $dir ) {
		File::List::Object::Exception::Parameter->throw(
			parameter => "dir: $dir is not a directory",
			where     => '->readdir'
		);
	}

	# Open directory.
	my $dir_object = IO::Dir->new($dir);
	if ( !defined $dir_object ) {
		File::List::Object::Exception->throw("Error reading directory $dir: $!");
	}

	# Read a file from the directory.
	my $file = $dir_object->read();

	while ( defined $file ) {

		# Check to make sure it isn't . or ..
		if ( ( $file ne curdir() ) and ( $file ne updir() ) ) {

			# Check for another directory.
			my $filespec = catfile( $dir, $file );
			if ( -d $filespec ) {

				# Read this directory.
				$self->readdir($filespec);
			} else {

				# Add the file!
				$self->_add_file($filespec, 1);
			}
		} ## end if ( ( $file ne q{.} )...

		# Next one, please?
		$file = $dir_object->read();
	} ## end while ( defined $file )

	return $self;
} ## end sub readdir

=head2 load_file

	$filelist = $filelist->load_file('C:\perl\.packlist');

Adds the files listed in the file passed in to the filelist.

This includes files that do not exist.

=cut

sub load_file {
	my ( $self, $packlist ) = @_;

	# Check parameters.
	if (not _STRING($packlist) ) {
		File::List::Object::Exception::Parameter->throw(
			parameter => 'packlist',
			where     => '->load_file'
		);
	}
	if (not -r $packlist ) {
		File::List::Object::Exception::Parameter->throw(
			parameter => "packlist: $packlist cannot be read",
			where     => '->load_file'
		);
	}

	# Read .packlist file.
	my $fh = IO::File->new( $packlist, 'r' );
	if ( not defined $fh ) {
		File::List::Object::Exception->throw("Error reading packlist file $packlist: $!");
	}
	my @files_list = <$fh>;
	$fh->close;
	my $file;

	# Insert list of files read into this object. Chomp on the way.
	my @files = map { ## no critic 'ProhibitComplexMappings'
		$file = $_;
		chomp $file;
		$file;
	} @files_list;
	foreach my $file_to_add (@files) {
		$self->_add_file($file_to_add, 1);
	}

	return $self;
} ## end sub load_file

=head2 load_array

	$filelist = $filelist->load_array(@files_list);

Adds the files listed in the array passed in to the filelist.

=cut

sub load_array {
	my ( $self, @files_list ) = @_;

	# Add each file in the array - if it is a file.
  FILE:
	foreach my $file (@files_list) {
		next FILE if not -f $file;
		$self->_add_file($file, 1);
	}

	return $self;
} ## end sub load_array

=head2 add_file

	$filelist = $filelist->add_file('C:\readme.txt');

Adds the files listed in the array passed in to the filelist.

The file being added must exist.

=cut

sub add_file {
	my ( $self, $file ) = @_;

	# Check parameters.
	if ( not _STRING($file) ) {
		File::List::Object::Exception::Parameter->throw(
			parameter => 'file',
			where     => 'add_file'
		);
	}

	if ( not -f $file ) {
		File::List::Object::Exception::Parameter->throw(
			parameter => "file: $file is not a file",
			where     => 'add_file'
		);
	}

	$self->_add_file($file, 1);

	return $self;
} ## end sub add_file

=head2 subtract

	$filelist = $filelist->subtract($filelist2);

Removes the files listed in the filelist object passed in.

=cut

sub subtract {
	my ( $self, $subtrahend ) = @_;

	# Check parameters
	if ( not _INSTANCE( $subtrahend, 'File::List::Object' ) ) {
		File::List::Object::Exception::Parameter->throw(
			parameter => 'subtrahend',
			where     => '->subtract'
		);
	}

	my @files_to_remove = $subtrahend->_get_files_array();
	$self->_delete_files(@files_to_remove);

	return $self;
} ## end sub subtract

=head2 add

	$filelist = $filelist->add($filelist2);

Adds the files listed in the filelist object passed in.

=cut

sub add {
	my ( $self, $term ) = @_;

	# Check parameters
	if ( not _INSTANCE( $term, 'File::List::Object' ) ) {
		File::List::Object::Exception::Parameter->throw(
			parameter => 'term',
			where     => '->add'
		);
	}

	# Add the two hashes together.
	my %files = ( %{ $self->_get_files_hashref() }, %{ $term->_get_files_hashref() } );
	$self->_set_files_hashref(\%files);

	return $self;
} ## end sub add

=head2 move

	$filelist = $filelist->move($file1, $file2);

Removes the first file passed in, and adds the second one to the filelist.

The second file need not exist yet.

=cut

sub move {
	my ( $self, $from, $to ) = @_;

	# Check parameters.
	if ( not _STRING($from) ) {
		File::List::Object::Exception::Parameter->throw(
			parameter => 'from',
			where     => '::Filelist->move'
		);
	}
	if (not _STRING($to) ) {
		File::List::Object::Exception::Parameter->throw(
			parameter => 'to',
			where     => '::Filelist->move'
		);
	}

	# Move the file if it exists.
	if ( $self->_is_file($from) ) {
		$self->_delete_files($from);
		$self->_add_file($to, 1);
	}

	return $self;
} ## end sub move

=head2 move_dir

	$filelist = $filelist->move_dir($dir1, $dir2);

Moves the files that would be in the first directory passed in into the 
second directory within the filelist.

This does not mode the files on disk, and the second directory and the files
in it need not exist yet.

=cut

sub _move_dir_grep {
	my $in = catfile(shift, q{});
	my $from = catfile(shift, q{});

	return ($in =~ m{\A\Q$from\E}msx) ? 1 : 0;
}

sub move_dir {
	my ( $self, $from, $to ) = @_;

	# Check parameters.
	if ( not _STRING($from) ) {
		File::List::Object::Exception::Parameter->throw(
			parameter => 'from',
			where     => '->move_dir'
		);
	}
	if ( not _STRING($to) ) {
		File::List::Object::Exception::Parameter->throw(
			parameter => 'to',
			where     => '->move_dir'
		);
	}

	# Find which files need moved.
	my @files_to_move =
	  grep { _move_dir_grep($_, $from) }
	  $self->_get_files_array();
	my $to_file;
	foreach my $file_to_move (@files_to_move) {

		# Get the correct name.
		$to_file = $file_to_move;
		$to_file =~ s{\A\Q$from\E}{$to}msx;

		# "move" the file.
		$self->_delete_files($file_to_move);
		$self->_add_file($to_file, 1);
	}

	return $self;
} ## end sub move_dir

=head2 filter

	$filelist = $filelist->filter([$string1, $string2, ...]);

Removes the files from the list whose names begin with the strings listed. 

=cut

sub filter {
	my ( $self, $re_list ) = @_;

	# Define variables to use.
	my @files_list = $self->_get_files_array();

	my @files_to_remove;

	# Filtering out values that match the regular expressions.
	foreach my $re ( @{$re_list} ) {
		push @files_to_remove, grep {m/\A\Q$re\E/msx} @files_list;
	}
	$self->_delete_files(@files_to_remove);

	return $self;
} ## end sub filter

=head2 as_string

	$string = $filelist->as_string();
	print $filelist2->as_string();
	
Prints out the files contained in the list, sorted, one per line. 

=cut

sub as_string {
	my $self = shift;

	my @files_list = sort {_sorter} $self->_get_files_array();

	return join "\n", @files_list;
}

1; # Magic true value required at end of module
__END__
  
=head1 DIAGNOSTICS

All diagnostics are returned as L<Exception::Class::Base|Exception::Class::Base> 
subclasses in the C<< File::List::Object::Exception >> subtree.

=over

=item C<< File::List::Object error: Parameter missing or invalid: %s >>

An invalid parameter was passed in. More information about why it was 
invalid may be returned.

(Returned as a C<< File::List::Object::Exception::Parameter >>> object)

=back

=head1 CONFIGURATION AND ENVIRONMENT

File::List::Object requires no configuration files or environment variables.

=for readme continue

=head1 DEPENDENCIES

Dependencies of this module that are non-core in perl 5.8.1 include 
L<Moose|Moose> version 0.79, L<Exception::Class|Exception::Class> version 
1.29, L<Params::Util|Params::Util> version 0.35, 
L<MooseX::AttributeHelpers|MooseX::AttributeHelpers> version 0.17, and 
L<version.pm|version> version 0.76.

=for readme stop

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-file-list-object@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell, C<< <csjewell@cpan.org> >>

=for readme continue

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Curtis Jewell C<< <csjewell@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=for readme stop

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
