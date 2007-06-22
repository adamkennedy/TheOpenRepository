package Email::Send::HTTP::Post;

=pod

=head1 NAME

Email::Send::HTTP::Post - Email via HTTP for when there's no other way

=head1 SYNOPSIS

  The author is an idiot who forgot to write the synopsis

=head1 DESCRIPTION

This is not an L<Email::Send> driver you should use if you can use
something (anything) better.

However, there are times when you want to send an email in a hideously
constrained networking environment, or when you expect the code to be
running in strange and interesting places.

Non-unix operating systems, laptops in airports, internet cafes, scripts
running from portable flash drives, heavily firewalled and proxied
corporate networks. All those sorts of situations which tend to violate
your assumption about what having "internet access" actually means.

This module, paired with something like L<CGI::Email::Relay> running on
almost any cheap shared hosting account or on your own server, will let
you create a lowest-common-denominator email channel for sending out
messages from applications.

The message is sent as a POST request, with the message container in the
"message" CGI parameter.

=cut

use strict;
use Return::Value  ();
use LWP::UserAgent ();
use Params::Util   qw{
	_STRING
	_IDENTIFIER
	_ARRAY
	_HASH
	_INSTANCE
	};

use Object::Tiny qw{
	uri
	message_param
	agent
	auth_realm
	auth_user
	auth_pass
	user_agent
};

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Email::Send Driver Interface

sub is_available {
	!! eval { require LWP::UserAgent; }
}

sub send {
	my $class   = shift;
	my $message = shift;

	# Create the user agent
	my $self = $class->new( @_ )
		or failure "Failed to create LWP::UserAgent";

	# Send the request
	my $rv = $self->user_agent->post( $self->uri, {
		$self->message_param => $message->as_string,
	} );
	if ( $rv->is_success ) {
		return success;
	} else {
		return failure "Failed to send message";
	}
}





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Check the target URI
	unless ( _INSTANCE($self->uri, 'URI') or _STRING($self->uri) ) {
		return undef;
	}

	# Check the field to write the message to
	unless ( defined $self->message_param ) {
		$self->{message_param} = 'message';
	}
	unless ( _IDENTIFIER($self->message_param) ) {
		return undef;
	}

	# Check or create the user agent
	unless ( _INSTANCE($self->user_agent, 'LWP::UserAgent') ) {
		if ( _HASH($self->user_agent) ) {
			$self->{user_agent} = LWP::UserAgent->new( %{$self->user_agent} );
		} else {
			$self->{user_agent} = LWP::UserAgent->new;
		}
		unless ( _INSTANCE($self->user_agent, 'LWP::UserAgent') ) {
			return undef;
		}
	}

	# Check and apply credentials if needed
	if ( $self->auth_realm and $self->auth_user and $self->auth_pass ) {
		$self->user_agent->credentials(
			$self->uri,
			$self->auth_realm,
			$self->auth_user,
			$self->auth_pass,
		);
	}

	return $self;
}

1;

=pod

=head1 SUPPORT

No support is available for this module

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

