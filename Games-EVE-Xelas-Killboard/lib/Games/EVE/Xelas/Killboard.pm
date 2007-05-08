package Games::EVE::Xelas::Killboard;

# Package for interacting with the Xelas killboard

use 5.005;
use strict;
use Carp              'croak';
use File::Slurp       ();
use Params::Util      qw{ _IDENTIFIER _POSINT _SCALAR _INSTANCE };
use WWW::Mechanize    ();
use HTML::TreeBuilder ();
use Object::Destroyer ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	home
	trace
	agent
	mech
	};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults and check params
	$self->{home}  ||= 'http://gotr0ot.org/kb/';
	$self->{trace} ||= 0;
	$self->{agent} ||= ref($self) . '/' . $VERSION;
	$self->{mech}  ||= WWW::Mechanize->new(
		agent       => $self->agent,
		cookie_jar  => undef,
		stack_depth => 100,
		);
	unless ( _INSTANCE($self->mech, 'WWW::Mechanize') ) {
		croak("The mech params is not a valid WWW::Mechanize object");
	}

	# Try to find the front page of the killboard
	$self->get_home;

	$self;
}





#####################################################################
# Main Methods

sub post_killmail {
	my $self     = shift;
	my $killmail = _INSTANCE(shift, 'Games::EVE::Killmail')
		or croak('Did not provide a killmail object to post_killmail');

	
}





#####################################################################
# Request Methods

sub get_home {
	my $self = shift;
	return $self->get('');
}

sub get_add_form {
	my $self = shift;
	return $self->get(die "CODE INCOMPLETE");
}





#####################################################################
# Mechanize Wrappers

# Provides a wrapper around the mech get to get the right URI
sub get {
	my $self = shift;
	my $path = shift || '';
	my $uri  = $self->home . $path;
	$self->say("GET $uri");
	my $rv = $self->mech->get( $uri, @_ );
	unless ( $self->mech->success ) {
		croak("Failed to GET $uri");
	}
	return $rv;
}

sub uri {
	shift->mech->uri(@_);
}

sub content {
	shift->mech->content(@_);
}

sub content_tree {
	my $self = shift;
	my $html = $self->content;
	my $tree = HTML::TreeBuilder->new_from_content( $html );
	unless ( _INSTANCE($tree, 'HTML::TreeBuilder') ) {
		croak("Failed to parse HTML page " . $self->uri);
	}
	my $safe = Object::Destroyer->new( $tree, 'delete' );
	unless ( _INSTANCE($tree, 'HTML::TreeBuilder') ) {
		croak("Failed to create safe HTML tree");
	}
	return $safe;
}





#####################################################################
# Support Methods

sub say {
	my $self = shift;
	my $msg  = shift;
	if ( $self->trace > 1 ) {
		$msg =~ s/\n$//;
		print $msg . "\n";
	} elsif ( $self->trace ) {
		if ( $msg =~ /^(GET|POST)/ ) {
			print ".";
		} else {
			print $msg;
		}
	}
	return 1;
}

1;
