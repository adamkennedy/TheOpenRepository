package TinyAuth;

use 5.005;
use strict;
use CGI          ();
use Params::Util qw{ _IDENTIFIER _INSTANCE };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	config
	cgi
};





#####################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( _INSTANCE($self->config, 'YAML::Tiny') ) {
		croak("The config param was not a YAML::Tiny object");
	}
	unless ( _INSTANCE($self->cgi, 'CGI') ) {
		croak("The cgi param was not a CGI object");
	}

	return $self;
}





#####################################################################
# Convenience and Support Methods

sub print {
	my $self = shift;
	print STDOUT @_;
}

BEGIN {
	my @functions = qw{
		header start_html end_html
		p
	};
	foreach ( @functions ) {
		eval "sub cgi_$_ {\n\tmy \$self = shift;\n\t\$self->print( \$self->cgi->$_(\@_) );\n}\n";
		$@ and die "Failed to create method for CGI::$_";
	}
}

sub run {
	my $self   = shift;
	my $action = _IDENTIFIER($self->cgi->param('a')) || 'view_index';
	unless ( $action =~ /^(?:view|action)_/ ) {
		die "Illegal action";
	}
	return $self->$action();
}





#####################################################################
# View Methods

sub view_index {
	my $self = shift;
	$self->cgi_header;
	$self->cgi_start_html("TinyAuth $VERSION");
	$self->cgi_p('Hello World!');
	$self->cgi_end_html;
	return 1;	
}

1;

__END__

=pod

=head1 NAME

TinyAuth - Simple web/mobile authentication

=head1 DESCRIPTION

TinyAuth is a web application for managing a set of email-based usernames
and passwords, generally for managing access to a web-based resource, such
as a subversion repository.

It users extremely simple HTML, so that the application can be used both
with a regular browser and with the web browsers available in many mobile
phones.

This allows the management of users in an extremely accessible way, and
allows for situations in which no PC or regular internet connection is
available.

