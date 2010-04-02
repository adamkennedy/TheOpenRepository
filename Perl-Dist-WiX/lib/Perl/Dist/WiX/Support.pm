package Perl::Dist::WiX::Support;

=pod

=head1 NAME

Perl::Dist::WiX::Support - Provides support routines for building a Win32 perl distribution.

=head1 VERSION

This document describes Perl::Dist::WiX::Support version 1.102_103.

=head1 SYNOPSIS

	# This module is not to be used independently.
	# It provides methods to be called on a Perl::Dist::WiX object.
  

=head1 DESCRIPTION

This module provides support methods for copying, extracting, and executing 
files, directories,  and programs for L<Perl::Dist::WiX|Perl::Dist::WiX>.

=cut

use 5.008001;
use Moose;
use English qw( -no_match_vars );
use File::Spec::Functions qw( catdir catfile );
use File::Remove qw();
use File::Basename qw();
use File::Path qw();
use File::pushd qw();
use Archive::Tar 1.42 qw();
use Archive::Zip qw( AZ_OK );
use LWP::UserAgent qw();

our $VERSION = '1.102_103';
$VERSION =~ s/_//ms;



=head1 METHODS

=head2 dir

	my $dir = $dist->dir(qw(perl bin));

Returns the subdirectory of the image directory with these components in 
order. 

=cut

sub dir {
	return catdir( shift->image_dir(), @_ );
}

sub _dir {
	print 'DEPRECATED: _dir(). Change to dir()';
	return shift->dir(@_);
}



=head2 file

	my $file = $dist->file(qw(perl bin perl.exe));

Returns the filename contained in the image directory with these components 
in order. 

=cut

sub file {
	return catfile( shift->image_dir(), @_ );
}

sub _file {
	print 'DEPRECATED: _file(). Change to file()';
	return shift->file(@_);
}



=head2 mirror_url

	my $file = $dist->mirror_url(
		'http://www.strawberryperl.com/strawberry-perl.zip',
		'C:\strawberry\',
	);
	
Downloads a file from the url in the first parameter to the directory in 
the second parameter.

Returns where the file was downloaded, including filename.

=cut

sub mirror_url {
	my ( $self, $url, $dir ) = @_;

	# If our caller was install_par, don't display anything.
	my $no_display_trace = 0;
	my (undef, undef, undef, $sub,  undef,
		undef, undef, undef, undef, undef
	) = caller 0;
	if ( $sub eq 'install_par' ) { $no_display_trace = 1; }

	# Check if the file already is downloaded.
	my $file = $url;
	$file =~ s{.+\/} # Delete anything before the last forward slash.
			  {}msx; ## (leaves only the filename.)
	my $target = catfile( $dir, $file );

	if ( $self->offline() and -f $target ) {
		return $target;
	}

	# Error out - we can't download.
	if ( $self->offline() and not $url =~ m{\Afile://}msx ) {
		PDWiX->throw("Currently offline, cannot download $url.\n");
	}

	# Create the directory to download to if required.
	File::Path::mkpath($dir);

	# Now download the file.
	$self->trace_line( 2, "Downloading file $url...\n", $no_display_trace );
	if ( $url =~ m{\Afile://}msx ) {

		# Don't use WithCache for files (it generates warnings)
		my $ua = LWP::UserAgent->new();
		my $r = $ua->mirror( $url, $target );
		if ( $r->is_error ) {
			$self->trace_line( 0,
				"    Error getting $url:\n" . $r->as_string . "\n" );
		} elsif ( $r->code == HTTP::Status::RC_NOT_MODIFIED ) {
			$self->trace_line( 2, "(already up to date)\n",
				$no_display_trace );
		}
	} else {

		my $ua = $self->user_agent();
		my $r = $ua->mirror( $url, $target );
		if ( $r->is_error ) {
			$self->trace_line( 0,
				"    Error getting $url:\n" . $r->as_string . "\n" );
		} elsif ( $r->code == HTTP::Status::RC_NOT_MODIFIED ) {
			$self->trace_line( 2, "(already up to date)\n",
				$no_display_trace );
		}
	} ## end else [ if ( $url =~ m{\Afile://}msx)]

	# Return the location downloaded to.
	return $target;
} ## end sub mirror_url

sub _mirror {
	print 'DEPRECATED: _mirror(). Change to mirror_url()';
	return shift->mirror_url(@_);
}



=head2 copy_file

	# Copy a file to a directory.
	$dist->copy_file(
		'C:\strawberry\perl\bin\perl.exe',
		'C:\strawberry\perl\lib\'
	);

	# Copy a file to a file.
	$dist->copy_file(
		'C:\strawberry\perl\bin\perl.exe',
		'C:\strawberry\perl\lib\perl.exe'
	);
	
	# Copy a directory to a directory.
	$dist->copy_file(
		'C:\strawberry\license\',
		'C:\strawberry\text\'
	);
	
Copies a file or directory into a directory, or a file to another file.

If you are copying a file, the destination file already exists, and the 
destination file is not writable, the destination is temporarily set 
to be writable, the copy is performed, and the destination is set to 
read-only.

=cut

sub copy_file {
	my ( $self, $from, $to ) = @_;
	my $basedir = File::Basename::dirname($to);
	File::Path::mkpath($basedir) unless -e $basedir;
	$self->trace_line( 2, "Copying $from to $to\n" );

	if ( -f $to and not -w $to ) {
		require Win32::File::Object;

		# Make sure it isn't readonly
		my $file = Win32::File::Object->new( $to, 1 );
		my $readonly = $file->readonly();
		$file->readonly(0);

		# Do the actual copy
		File::Copy::Recursive::rcopy( $from, $to )
		  or PDWiX->throw("Copy error: $OS_ERROR");

		# Set it back to what it was
		$file->readonly($readonly);
	} else {
		File::Copy::Recursive::rcopy( $from, $to )
		  or PDWiX->throw("Copy error: $OS_ERROR");
	}
	return 1;
} ## end sub copy_file

sub _copy {
	print 'DEPRECATED: _copy(). Change to copy_file()';
	return shift->copy_file(@_);
}


=head2 move_file

	# Move a file into a directory.
	$dist->move_file(
		'C:\strawberry\perl\bin\perl.exe',
		'C:\strawberry\perl\lib\'
	);

	# Move a file to a file.
	$dist->move_file(
		'C:\strawberry\perl\bin\perl.exe',
		'C:\strawberry\perl\lib\perl.exe'
	);
	
	# Move a directory to a directory.
	$dist->move_file(
		'C:\strawberry\license\',
		'C:\strawberry\text\'
	);

Moves a file or directory into a directory, or a file to another file.

=cut

sub move_file {
	my ( $self, $from, $to ) = @_;
	my $basedir = File::Basename::dirname($to);
	File::Path::mkpath($basedir) unless -e $basedir;
	$self->trace_line( 2, "Moving $from to $to\n" );
	File::Copy::Recursive::rmove( $from, $to )
	  or PDWiX->throw("Move error: $OS_ERROR");

	return;
}

sub _move {
	print 'DEPRECATED: _move(). Change to move_file()';
	return shift->move_file(@_);
}



=head2 push_dir

	my $dir = $dist->dir($dist->image_dir(), qw(perl bin));

Changes the current directory to the location specified by the
components passed in.

When the object that is returned (a L<File::pushd|File::pushd> 
object) is destroyed, the current directory is changed back to
the previous value.

=cut 

sub push_dir {
	my $self = shift;
	my $dir  = catdir(@_);
	$self->trace_line( 2, "Lexically changing directory to $dir...\n" );
	return File::pushd::pushd($dir);
}

sub _pushd {
	print 'DEPRECATED: _pushd(). Change to push_dir()';
	return shift->push_dir(@_);
}



=head2 execute_build

	$dist->execute_build('install');

Executes a Module::Build script with the options given (which can be
empty).

=cut 

sub execute_build {
	my $self   = shift;
	my @params = @_;
	$self->trace_line( 2,
		join( q{ }, '>', 'Build.bat', @params ) . qq{\n} );
	$self->execute_any( 'Build.bat', @params )
	  or PDWiX->throw('build failed');
	PDWiX->throw('build failed (OS error)') if ( $CHILD_ERROR >> 8 );
	return 1;
}

sub _build {
	print 'DEPRECATED: _build(). Change to execute_build()';
	return shift->execute_build(@_);
}



=head2 execute_make

	$dist->execute_make('install');

Executes a ExtUtils::MakeMaker-generated makefile with the options given 
(which can be empty) using the C<dmake> being installed.

=cut 

sub execute_make {
	my $self   = shift;
	my @params = @_;
	$self->trace_line( 2,
		join( q{ }, '>', $self->bin_make(), @params ) . qq{\n} );
	$self->execute_any( $self->bin_make(), @params )
	  or PDWiX->throw('make failed');
	PDWiX->throw('make failed (OS error)') if ( $CHILD_ERROR >> 8 );
	return 1;
}

sub _make {
	print 'DEPRECATED: _make(). Change to execute_make()';
	return shift->execute_make(@_);
}



=head2 execute_perl

	$self->execute_perl('Build.PL', 'INSTALLDIR=vendor');

Executes a perl script (given in the first parameter) with the 
options given using the perl being installed.

=cut 

sub execute_perl {
	my $self   = shift;
	my @params = @_;

	unless ( -x $self->bin_perl() ) {
		PDWiX->throw( q{Can't execute } . $self->bin_perl() );
	}

	$self->trace_line( 2,
		join( q{ }, '>', $self->bin_perl(), @params ) . qq{\n} );
	$self->execute_any( $self->bin_perl(), @params )
	  or PDWiX->throw('perl failed');
	PDWiX->throw('perl failed (OS error)') if ( $CHILD_ERROR >> 8 );
	return 1;
} ## end sub execute_perl

sub _perl {
	print 'DEPRECATED: _perl(). Change to execute_perl()';
	return shift->execute_perl(@_);
}



=head2 execute_any

	$self->execute_any('dmake');
	
Executes a program, saving the STDOUT and STDERR in the files specified by
C<debug_stdout()> and C<debug_stderr()>.

=cut 

sub execute_any {
	my $self = shift;

	# Remove any Perl installs from PATH to prevent
	# "which" discovering stuff it shouldn't.
	my @path = split /;/ms, $ENV{PATH};
	my @keep = ();
	foreach my $p (@path) {

		# Strip any path that doesn't exist
		next unless -d $p;

		# Strip any path that contains either dmake or perl.exe.
		# This should remove both the ...\c\bin and ...\perl\bin
		# parts of the paths that Vanilla/Strawberry added.
		next if -f catfile( $p, 'dmake.exe' );
		next if -f catfile( $p, 'perl.exe' );

		# Strip any path that contains either unzip or gzip.exe.
		# These two programs cause perl to fail its own tests.
		next if -f catfile( $p, 'unzip.exe' );
		next if -f catfile( $p, 'gzip.exe' );

		push @keep, $p;
	} ## end foreach my $p (@path)

	# Reset the environment
	local $ENV{LIB}      = undef;
	local $ENV{INCLUDE}  = undef;
	local $ENV{PERL5LIB} = undef;
	local $ENV{PATH} = $self->get_path_string() . q{;} . join q{;}, @keep;

	$self->trace_line( 3, "Path during execute_any: $ENV{PATH}\n" );

	# Execute the child process
	return IPC::Run3::run3( [@_], \undef, $self->debug_stdout(),
		$self->debug_stderr(), );
} ## end sub execute_any

sub _run3 {
	print 'DEPRECATED: _run3(). Change to execute_any()';
	return shift->execute_any(@_);
}



=head2 extract_archive

	$dist->extract_archive($archive, $to);

Extracts an archive file (set in the first parameter) to a specified 
directory (set in the second parameter).

The archive file must be a .tar.gz or a .zip file.

TODO: Add .tar.xz files.

=cut 

sub extract_archive {
	my ( $self, $from, $to ) = @_;
	File::Path::mkpath($to);
	my $wd = $self->push_dir($to);

	my @filelist;

	$self->trace_line( 2, "Extracting $from...\n" );
	if ( $from =~ m{[.] zip\z}msx ) {
		my $zip = Archive::Zip->new($from);

		if ( not defined $zip ) {
			PDWiX->throw("Could not open archive $from for extraction");
		}

# I can't just do an extractTree here, as I'm trying to
# keep track of what got extracted.
		my @members = $zip->members();

		foreach my $member (@members) {
			my $filename = $member->fileName();
			$filename = _convert_name($filename)
			  ;                        # Converts filename to Windows format.
			my $status = $member->extractToFileNamed($filename);
			if ( $status != AZ_OK ) {
				PDWiX->throw('Error in archive extraction');
			}
			push @filelist, $filename;
		}

	} elsif ( $from =~ m{ [.] tar [.] gz | [.] tgz}msx ) {
		local $Archive::Tar::CHMOD = 0;
		my @fl = @filelist = Archive::Tar->extract_archive( $from, 1 );
		@filelist = map { catfile( $to, $_ ) } @fl;
		if ( !@filelist ) {
			PDWiX->throw('Error in archive extraction');
		}

	} else {
		PDWiX->throw("Didn't recognize archive type for $from");
	}
	return @filelist;
} ## end sub extract_archive

sub _extract {
	print 'DEPRECATED: _extract(). Change to extract_archive()';
	return shift->extract_archive(@_);
}

sub _convert_name {
	my $name     = shift;
	my @paths    = split m{\/}ms, $name;
	my $filename = pop @paths;
	$filename = q{} unless defined $filename;
	my $local_dirs = @paths ? catdir(@paths) : q{};
	my $local_name = catpath( q{}, $local_dirs, $filename );
	$local_name = rel2abs($local_name);
	return $local_name;
}

sub _extract_filemap {
	my ( $self, $archive, $filemap, $basedir, $file_only ) = @_;

	my @files;

	if ( $archive =~ m{[.] zip\z}msx ) {

		my $zip = Archive::Zip->new($archive);
		my $wd  = $self->push_dir($basedir);
		while ( my ( $f, $t ) = each %{$filemap} ) {
			$self->trace_line( 2, "Extracting $f to $t\n" );
			my $dest = catfile( $basedir, $t );

			my @members = $zip->membersMatching("^\Q$f");

			foreach my $member (@members) {
				my $filename = $member->fileName();
#<<<
				$filename =~
				  s{\A\Q$f}    # At the beginning of the string, change $f 
				   {$dest}msx; # to $dest.
#>>>
				$filename = _convert_name($filename);
				my $status = $member->extractToFileNamed($filename);

				if ( $status != AZ_OK ) {
					PDWiX->throw('Error in archive extraction');
				}
				push @files, $filename;
			} ## end foreach my $member (@members)
		} ## end while ( my ( $f, $t ) = each...)

	} elsif ( $archive =~ m{[.] tar [.] gz | [.] tgz}msx ) {
		local $Archive::Tar::CHMOD = 0;
		my $tar = Archive::Tar->new($archive);
		for my $file ( $tar->get_files() ) {
			my $f       = $file->full_path();
			my $canon_f = File::Spec::Unix->canonpath($f);
			for my $tgt ( keys %{$filemap} ) {
				my $canon_tgt = File::Spec::Unix->canonpath($tgt);
				my $t;

#<<<
				if ($file_only) {
					next unless
					  $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E\z}imsx;
					( $t = $canon_f ) =~ s{\A([^/]+[/])?\Q$canon_tgt\E\z}
										  {$filemap->{$tgt}}imsx;
				} else {
					next unless
					  $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E}imsx;
					( $t = $canon_f ) =~ s{\A([^/]+[/])?\Q$canon_tgt\E}
										  {$filemap->{$tgt}}imsx;
				}
#>>>
				my $full_t = catfile( $basedir, $t );
				$self->trace_line( 2, "Extracting $f to $full_t\n" );
				$tar->extract_file( $f, $full_t );
				push @files, $full_t;
			} ## end for my $tgt ( keys %{$filemap...})
		} ## end for my $file ( $tar->get_files...)

	} else {
		PDWiX->throw("Didn't recognize archive type for $archive");
	}

	return @files;
} ## end sub _extract_filemap



=head2 make_path

	$dist->make_path('perl\bin');

Creates a path if it does not already exist.
	
The path passed in is converted to an absolute path using 
L<File::Spec::Functions|File::Spec::Functions>::L<rel2abs()|File::Spec/rel2abs>
before creation occurs.

=cut 

sub make_path {
	my $class = shift;
	my $dir   = rel2abs(shift);

	File::Path::mkpath($dir) unless -d $dir;
	unless ( -d $dir ) {
		PDWiX->throw("Failed to create directory $dir");
	}
	return $dir;
}

sub _make_path {
	print 'DEPRECATED: _make_path(). Change to make_path()';
	return shift->make_path(@_);
}



=head2 remake_path

	$dist->make_path('perl\bin');

Creates a path, removing all the files in it if the path already exists.
	
The path passed in is converted to an absolute path using 
L<File::Spec::Functions|File::Spec::Functions>::L<rel2abs()|File::Spec/rel2abs>
before creation occurs.

=cut 

sub remake_path {
	my $class = shift;
	my $dir   = rel2abs(shift);
	File::Remove::remove( \1, $dir ) if -d $dir;
	File::Path::mkpath($dir);

	unless ( -d $dir ) {
		PDWiX->throw("Failed to recreate directory $dir");
	}
	return $dir;
}

sub _remake_path {
	print 'DEPRECATED: _remake_path(). Change to remake_path()';
	return shift->remake_path(@_);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
