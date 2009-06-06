package Module::Release::UploadOwnSite;

use strict;
use warnings;
use base qw(Exporter);
use vars qw($VERSION);
require Data::Dumper;

our @EXPORT = qw(ownsite_upload ownsite_password);

$VERSION = '0.01';

=head1 NAME

Module::Release::UploadOwnSite - Upload to personal site

=head1 SYNOPSIS

The release2 script will automatically load this module if it thinks that you
want to upload to your own site.

=head1 DESCRIPTION

=over 4

=item ownsite_upload

Looks in local_name to get the name and version of the distribution file.

=cut

sub ownsite_upload {
	my $self = shift;

	my $user = $self->config->ownsite_ftp_user();
	return unless $user;

    my $password = $self->config->ownsite_ftp_pass();
    my $dir = $self->config->ownsite_ftp_upload_dir();
    my $host = $self->config->ownsite_ftp_host();
	
	my $local_file = $self->local_file;
	
	$self->_print("Now uploading to $host\n" );
	
	$self->ftp_upload(
		user       => $user,
		password   => $password,
		upload_dir => $dir,
		hostname   => $host,
	);
}

sub ownsite_password {
	my $self = shift;
	my $pass;
	
	if( $pass = $self->config->ownsite_ftp_pass() || $self->get_env_var( "FTP_PASS" )  )
		{
		$self->config->set( 'ownsite_ftp_pass', $pass ); 
		}
		
	$self->_print( "FTP site pass is $pass\n" );

}


=back

=head1 SEE ALSO

L<Module::Release>

=head1 SOURCE AVAILABILITY

This source is in Github:

	git://github.com/briandfoy/module-release.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007-2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
