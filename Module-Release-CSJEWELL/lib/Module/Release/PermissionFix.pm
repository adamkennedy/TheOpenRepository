package Module::Release::PermissionFix;

use strict;
use warnings;
use base qw(Exporter);
use vars qw($VERSION);
use Archive::Tar;

our @EXPORT = qw(fix_permission);

$VERSION = '0.01';

=head1 NAME

Module::Release::VersionPmFix - Fixes the 'v' that version.pm adds.

=head1 SYNOPSIS

The release2 script will automatically load this module if it thinks that you
want to announce your module on Twitter.

=head1 DESCRIPTION

=over 4

=item fix_version

Fixes local_name and renames the distribution file.

=cut

sub fix_permission {
	my $self = shift;

	local $Archive::Tar::DO_NOT_USE_PREFIX = 1;

	my $dist    = $self->local_file;

    my $fixes;
    my $tar = Archive::Tar->new;
    $tar->read($dist);
    my @files = $tar->get_files;
    foreach my $file (@files) {
        my $fixedmode = my $mode = $file->mode;
        my $filetype = '';
        if ($file->is_file) {
            $filetype = 'file';
            if (substr(${ $file->get_content_by_ref }, 0, 2) eq '#!') {
                $fixedmode = 0775;
            } else {
                $fixedmode = 0664;
            }
        } elsif ($file->is_dir) {
            $filetype = 'dir';
            $fixedmode = 0775;
        } else {
            next;
        }
        next if $mode eq $fixedmode;
        $file->mode($fixedmode);
        $fixes++;
        $self->_debug(sprintf("Change mode %03o to %03o for %s '%s'\n", $mode, $fixedmode, $filetype, $file->name));
    }

    if ($fixes) {
		rename $dist, "$dist.bak" or die "Cannot rename file '$dist' to '$dist.bak': $!";
		$tar->write($dist, 9);
		$self->_print( "Permissions fixed: $dist.\n" );
    } else {
        $self->_print( "Permissions didn't need fixed: $dist.\n" );
    }	
}


=back

=head1 SEE ALSO

L<Module::Release>

=head1 SOURCE AVAILABILITY

None as of yet.

=head1 AUTHOR

Curtis Jewell, C<< <csjewell@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 Curtis Jewell.

You may redistribute this under the same terms as Perl itself.

=cut

1;
