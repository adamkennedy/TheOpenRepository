package Games::EVE::Griefwatch;

# Package for interacting with a griefwatch killboard

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
	$VERSION = '0.02';
}

use Object::Tiny qw{
	name
	trace
	agent
	mech
	cache
	};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults and check params
	unless ( _IDENTIFIER($self->name) ) {
		croak("Did not p\rovide a killboard name");
	}
	$self->{name}    = lc $self->name;
	$self->{trace} ||= 0;
	$self->{agent} ||= 'Games-EVE-Griefwatch/' . $VERSION;
	$self->{mech}  ||= WWW::Mechanize->new(
		agent       => $self->agent,
		cookie_jar  => undef,
		stack_depth => 100,
		);
	unless ( _INSTANCE($self->mech, 'WWW::Mechanize') ) {
		croak("The mech params is not a valid WWW::Mechanize object");
	}
	if ( defined $self->cache ) {
		unless (
			_STRING($self->cache)
			and
			-d $self->cache
			and
			-r $self->cache
			and
			-w $self->cache
		) {
			croak("Missing or invalid killmail cache");
		}
	}

	# Try to find the front page of the killboard
	$self->get_home;

	$self;
}





#####################################################################
# Main Methods

sub kills {
	my $self = shift;
	if ( $self->{kills} ) {
		# Return the cached version
		return @{$self->{kills}};
	}

	# Go to the kills page
	$self->get_kills;

	# Collect the ids, and iterate
	my @ids = ();
	while ( 1 ) {
		my $content = $self->content;
		push @ids, $self->parse_ids( \$content );
		my $next_uri = $self->parse_next( \$content );
		if ( $next_uri ) {
			$self->get($next_uri);
 		} else {
			last;
		}
	}

	my %seen = ();
	return sort grep { ! $seen{$_}++ } @ids;
}

sub losses {
	my $self = shift;
	if ( $self->{losses} ) {
		# Return the cached version
		return @{$self->{losses}};
	}

	# Go to the losses page
	$self->get_losses;

	# Collect the ids, and iterate
	my @ids = ();
	while ( 1 ) {
		my $content = $self->content;
		push @ids, $self->parse_ids( \$content );
		my $next_uri = $self->parse_next( \$content );
		if ( $next_uri ) {
			$self->get($next_uri);
 		} else {
			last;
		}
	}

	my %seen = ();
	return sort grep { ! $seen{$_}++ } @ids;
}

# Extract a killmail
sub rawmail {
	my $self = shift;
	my $id   = _POSINT(shift) or croak("Invalid killmail id");

	# Use the cached version if it exists
	my $file;
	if ( $self->cache ) {
		$file = File::Spec->catfile( $self->cache, "$id.kill" );
		if ( -f $file ) {
			my $string = File::Slurp::read_file( $file );
			return $string;
		}
	}

	# Go to the page for the kill
	$self->get_details($id);

	# Locate the mail content
	my $tree = $self->content_tree;
	my $rawmail = $self->find_rawmail( $tree );

	# Save a copy to the cache if needed
	if ( $self->cache ) {
		File::Slurp::write_file( $file, $rawmail );
	}

	return $rawmail;
}

# Find the raw mail within a tree
sub find_rawmail {
	my $self = shift;
	my $tree = _INSTANCE(shift, 'HTML::TreeBuilder')
		or croak("Did not pass a HTML::TreeBuilder to find_rawmail");

	# Find the mail div in the page
	my $mail = $tree->look_down(
		_tag => 'div',
		id   => 'mail',
		);
	unless ( $mail ) {
		croak("Failed to find mail div on page " . $self->uri);
	}

	# Remove any tags within this
	foreach my $tag ( $mail->find_by_tag_name('a', 'div', 'br') ) {
		if ( $tag->tag eq 'br' ) {
			$tag->replace_with("\n");
		} else {
			$tag->replace_with("");
		}
	}
	
	# The text contents should now just be the raw mail
	# Make sure it has no leading newlines, and a
	# single trailing newline before returning.
	my $rawmail = $mail->as_text;
	$rawmail =~ s/^\s+//s;
	$rawmail =~ s/\s*$/\n/s;

	return $rawmail;
}

sub parse_ids {
	my $self = shift;
	my $html = _SCALAR(shift) or croak("Did not pass SCALAR ref to parse_kills");
	my @ids  = $$html =~ /href\=\"\?p\=details\&amp\;kill\=(\d+)\"/gi;
	my %seen = ();
	return grep { ! $seen{$_}++ } @ids;
}

sub parse_next {
	my $self = shift;
	my $html = _SCALAR(shift) or croak("Did not pass SCALAR ref to parse_kills");
	if ( $$html =~ /\<a href\=\"(\?p\=\w+\&amp\;page\=\2\)"\>Next\<\/a\>/ ) {
		my $uri = $1;
		$uri =~ s/\&amp\;/&/gi;
		return $uri;
	} else {
		return undef;
	}
}





#####################################################################
# Request Abstractions

sub get_home {
	my $self = shift;
	return $self->get('');
}

sub get_kills {
	my $self = shift;
	return $self->get('kills');
}

sub get_losses {
	my $self = shift;
	return $self->get('losses');
}

sub get_next {
	my $self = shift;
	$self->mech->follow_link('Next');
}

sub get_details {
	my $self = shift;
	my $id   = _POSINT(shift)
		or croak("Did not pass killmail id to details");
	return $self->get( "details&kill=$id" );
}





#####################################################################
# Mechanize Wrappers

# Provides a wrapper around the mech get to get the right URI
sub get {
	my $self = shift;
	my $path = shift;
	my $name = $self->name;
	my $uri  = $path
		? $path =~ /^\?/
			? "http://$name.griefwatch.net/$path"
			: "http://$name.griefwatch.net/?p=$path"
		: "http://$name.griefwatch.net/";
	$self->say("GET $uri");
	my $rv = $self->mech->get( $uri, @_ );
	unless ( $self->mech->success ) {
		croak("Failed to GET $uri");
	}
	return $rv;
}

sub post {
	my $self = shift;
	my $path = shift;
	my $name = $self->name;
	my $uri  =  "http://$name.griefwatch.net/?p=$path";
	$self->say("POST $uri");
	my $rv = $self->mech->post( $uri, @_ );
	unless ( $self->mech->success ) {
		croak("Failed to POST $uri");
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
