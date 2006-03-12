package HTTP::Daemon::Multiplex;

=pod

=head1 NAME

HTTP::Daemon::Multiplex - Create a HTTP::Daemon that does more than one thing

=head1 DESCRIPTION

The L<HTTP::Daemon> class provides a good base for writing a custom web
server. But it requires that you code all the way down to individual socket
management.

Sometimes you want a HTTP server that can do more than one thing. Accept
files at one path, serve files down a different path, etc etc. Something
closer to what you get with Apache, but still with the ability to custom
code and mix up different request handlers.

C<HTTP::Daemon::Multiple> is a subclass of L<HTTP::Daemon> that deals with
the basic socket management stuff, and lets you configure a set of
handlers.

When a request comes in to the server, it will compare the request against
each handler in turn, handing it off to the first one that the request
matches.

You then deal with the request and respond in the usual way.

=head1 STATUS

This module is considered experimental, pending a possible reorganisation
of its parent classes.

It is not yet recommended for use unless you are in contact with the author.

=head1 METHODS

=cut

use 5.005;
use strict;
use HTTP::Daemon ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

=pod

=head1 new

...

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

}

1;
