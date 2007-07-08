package File::Remove;

use strict;
use vars qw(@EXPORT_OK @ISA $VERSION $debug $unlink $rmdir);
BEGIN {
	$VERSION   = '0.37';
	@ISA       = qw(Exporter);
	@EXPORT_OK = qw(remove rm trash); # nothing by default :)

	# Booleanise the debug flag
	$debug = !! $debug;
}

# If we ever need a Mac::Glue object,
# we will want to cache it.
my $glue;

use File::Spec ();
use File::Path ();
use File::Glob ();

sub expand (@) {
	map { File::Glob::bsd_glob($_) } @_;
}

# $debug variable must be set before loading File::Remove.
# Convert to a constant to allow debugging code to be pruned out.
use constant DEBUG => $debug;

# Are we on VMS?
# If so copy File::Path and assume VMS::Filespec is loaded
use constant IS_VMS   => $^O eq 'VMS';

# Are we on Win32?
# If so write permissions does not imply deletion permissions
use constant IS_WIN32 => $^O eq 'MSWin32';





#####################################################################
# Main Functions

# acts like unlink would until given a directory as an argument, then
# it acts like rm -rf ;) unless the recursive arg is zero which it is by
# default
sub remove (@) {
	my $recursive = (ref $_[0] eq 'SCALAR') ? shift : \0;
	my @files     = expand @_;

	# Iterate over the files
	my @removes;
	foreach my $path ( @files ) {
                # need to check for symlink first
                # could be pointing to nonexisting/non-readable destination
		if ( -l $path ) {
			print "link: $path\n" if $debug;
			if ( $unlink ? $unlink->($path) : unlink($path) ) {
				push @removes, $path;
			}
			next;
                }
		unless ( -e $path ) {
			print "missing: $path\n" if DEBUG;
			push @removes, $path; # Say we deleted it
			next;
		}
		my $can_delete;
		if ( IS_VMS ) {
			$can_delete = VMS::Filespec::candelete($path);
		} elsif ( IS_WIN32 ) {
			# Assume we can delete it for the moment
			$can_delete = 1;
		} elsif ( -w $path ) {
			# We have write permissions already
			$can_delete = 1;
		} elsif ( $< == 0 ) {
			# Unixy and root
			$can_delete = 1;
		} elsif ( (lstat($path))[4] == $< ) {
			# I own the file
			$can_delete = 1;
		} else {
			# I don't think we can delete it
			$can_delete = 0;
		}
		unless ( $can_delete ) {
			print "nowrite: $path\n" if DEBUG;
			next;
		}

		if ( -f $path ) {
			print "file: $path\n" if DEBUG;
			unless ( -w $path ) {
				# Make the file writable (implementation from File::Path)
				(undef, undef, my $rp) = lstat $path or next;
				$rp &= 07777; # Don't forget setuid, setgid, sticky bits
				$rp |= 0600;  # Turn on user read/write
				chmod $rp, $path;
			}
			if ( $unlink ? $unlink->($path) : unlink($path) ) {
				# Failed to delete the file
				next if -e $path;
				push @removes, $path;
			}

		} elsif ( -d $path ) {
			print "dir: $path\n" if DEBUG;
			my $dir = File::Spec->canonpath( $path );
			if ( $$recursive ) {
				if ( File::Path::rmtree( [ $dir ], DEBUG, 0 ) ) {
					# Failed to delete the directory
					next if -e $path;
					push @removes, $path;
				}

			} else {
				my ($save_mode) = (stat $dir)[2];
				chmod $save_mode & 0777, $dir; # just in case we cannot remove it.
				if ( $rmdir ? $rmdir->($dir) : rmdir($dir) ) {
					# Failed to delete the directory
					next if -e $path;
					push @removes, $path;
				}
			}

		} else {
			print "???: $path\n" if DEBUG;
		}
	}

	return @removes;
}

sub rm (@) {
	goto &remove;
}

sub trash (@) {
	local $unlink = $unlink;
	local $rmdir  = $rmdir;

	if ( ref $_[0] eq 'HASH' ) {
		my %options = %{+shift @_};
		$unlink = $options{unlink};
		$rmdir  = $options{rmdir};

	} elsif ( $^O eq 'cygwin' || $^O =~ /^MSWin/ ) {
		eval 'use Win32::FileOp ();';
		die "Can't load Win32::FileOp to support the Recycle Bin: \$@ = $@" if length $@;
		$unlink = \&Win32::FileOp::Recycle;
		$rmdir  = \&Win32::FileOp::Recycle;

	} elsif ( $^O eq 'darwin' ) {
		unless ( $glue ) {
			eval 'use Mac::Glue ();';
			die "Can't load Mac::Glue::Finder to support the Trash Can: \$@ = $@" if length $@;
			$glue = Mac::Glue->new('Finder');
		}
		my $code = sub {
			my @files = map { Mac::Glue::param_type(Mac::Glue::typeAlias() => $_) } @_;
			$glue->delete(\@files);
		};
		$unlink = $code;
		$rmdir  = $code;
	} else {
		die "Support for trash() on platform '$^O' not available at this time.\n";
	}
	goto &remove;
}

sub undelete (@) {
	goto &trash;
}

1;

__END__

=pod

=head1 NAME

File::Remove - Remove files and directories

=head1 SYNOPSIS

    use File::Remove qw(remove);

    # removes (without recursion) several files
    remove qw( *.c *.pl );

    # removes (with recursion) several directories
    remove \1, qw( directory1 directory2 ); 

    # removes (with recursion) several files and directories
    remove \1, qw( file1 file2 directory1 *~ );

    # trashes (with support for undeleting later) several files
    trash qw( *~ );

=head1 DESCRIPTION

B<File::Remove::remove> removes files and directories.  It acts like
B</bin/rm>, for the most part.  Although C<unlink> can be given a list
of files, it will not remove directories; this module remedies that.
It also accepts wildcards, * and ?, as arguments for filenames.

B<File::Remove::trash> accepts the same arguments as B<remove>, with
the addition of an optional, infrequently used "other platforms"
hashref.

=head1 SUBROUTINES

=over 4

=item remove

Removes files and directories.  Directories are removed recursively like
in B<rm -rf> if the first argument is a reference to a scalar that
evaluates to true.  If the first arguemnt is a reference to a scalar
then it is used as the value of the recursive flag.  By default it's
false so only pass \1 to it.

In list context it returns a list of files/directories removed, in
scalar context it returns the number of files/directories removed.  The
list/number should match what was passed in if everything went well.

=item rm

Just calls B<remove>.  It's there for people who get tired of typing
B<remove>.

=item trash

Removes files and directories, with support for undeleting later.
Accepts an optional "other platforms" hashref, passing the remaining
arguments to B<remove>.

=over 4

=item Win32

Requires L<Win32::FileOp>.

Installation not actually enforced on Win32 yet, since L<Win32::FileOp>
has badly failing dependencies at time of writing.

=item OS X

Requires L<Mac::Glue>.

=item Other platforms

The first argument to trash() must be a hashref with two keys,
'rmdir' and 'unlink', each referencing a coderef.  The coderefs
will be called with the filenames that are to be deleted.

=back

=back

=head1 BUGS

See http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Remove for the
up-to-date bug listing.

=head1 AUTHOR

Taken over by Adam Kennedy E<lt>adamk@cpan.orgE<gt>, to fix the
"deep readonly files" bug, and do some more cleaning up.

Taken over by Richard Soderberg E<lt>perl@crystalflame.netE<gt>, so as
to port it to L<File::Spec> and add tests.

Original copyright: (c) 1998 by Gabor Egressy, E<lt>gabor@vmunix.comE<gt>.

All rights reserved.  All wrongs reversed.  This program is free software;
you can redistribute and/or modify it under the same terms as Perl itself.

=cut
