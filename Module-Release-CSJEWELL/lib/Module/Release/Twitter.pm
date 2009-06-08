package Module::Release::Twitter;

use strict;
use warnings;
use base qw(Exporter);
use vars qw($VERSION);
use Net::Twitter 3.00000;
require Data::Dumper;

our @EXPORT = qw(twit_upload twit_password);

$VERSION = '0.01';

=head1 NAME

Module::Release::Twitter - Twitter the module upload

=head1 SYNOPSIS

The release-csjewell script will automatically load this module if it 
thinks that you want to announce your module on Twitter.

=head1 DESCRIPTION

=over 4

=item twit_upload

Announces your upload to the Twitter account of your choice.

=cut

sub twit_upload {
	my $self = shift;

	my $local_file = $self->local_file;
	my $twit_user = $self->config->twit_user();
	return unless $user;
	
	my $twit_password = $self->config->twit_pass();

	my $string = "Uploaded $local_file to CPAN - find it on your local mirror in a few hours! #Perl";

	$self->_print( "Twitter: $string\n" );

	$self->_debug("Twitter: User: $twit_user Password: $twit_password\n");
	$self->_debug("Net::Twitter: Version: $Net::Twitter::VERSION\n");
	
	my $twit = Net::Twitter->new(
		traits    => [qw(API::REST)],
		username  => $twit_user, 
		password  => $twit_password,
		);

	eval { $twit->update($string) };
    if ( $@ ) {
        $self->_print( "Could not Twitter because: $@\n" );
    }	
}

=item twit_upload

Retrieves the password for your Twitter account.

=cut

sub twit_password {
	my $self = shift;
	my $pass;
	
	if( $pass = $self->config->twit_pass() || $self->get_env_var( "TWITTER_PASS" )  )
		{
		$self->config->set( 'twit_pass', $pass ); 
		}
		
}


=back

=head1 SEE ALSO

L<Module::Release>

=head1 SOURCE AVAILABILITY

This source is on the Open Repository:

	L<http://svn.ali.as/cpan/trunk/Module-Release-CSJEWELL/>

=head1 AUTHOR

Curtis Jewell, C<< <csjewell@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009, Curtis Jewell.

You may redistribute this under the same terms as Perl itself.

=cut

1;
