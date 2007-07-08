package TinyAuth;

=pod

=head1 NAME

TinyAuth - Extremely light-weight web-based authentication manager

=head1 DESCRIPTION

B<TinyAuth> is an extremely light-weight authentication management
web application, initially created to assist in managing a subversion
repository.

It is designed to provide the basic functionality of adding and removing
users, and handling password maintenance with as little code and fuss
as possible.

More importantly, it is intended to be extremely easy to install and
set up, even on shared hosting accounts. The interface is simple enough
that it can be used on typical limited-functionality browsers such as
the text-mode lynx browser, and the browsers found in most mobile phones.

The intent is to allow users and be added, removed and repaired from
anywhere, even without a computer or "regular" internet connection.

=cut

use 5.005;
use strict;
use CGI ();
use Params::Util qw{ _INSTANCE };
use Apache::Htpasswd::Shadow ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.03';
}

use Object::Tiny qw{
	config
	cgi
	action
	header
	title
	homepage
	auth_htpasswd
	auth_htshadow
	};





#####################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Check and set the config
	unless ( _INSTANCE($self->config, 'YAML::Tiny') ) {
		Carp::croak("Did not provide a config param");
	}

	# Set the header
	unless ( $self->header ) {
		$self->{header} = CGI::header( 'text/html' );
	}

	# Set the page title
	unless ( $self->title ) {
		$self->{title} ||= $self->config->[0]->{title};
		$self->{title} ||= __PACKAGE__ . ' ' . $VERSION;
	}

	# Set the homepage
	unless ( $self->homepage ) {
		$self->{homepage} ||= $self->config->[0]->{homepage};
		$self->{homepage} ||= 'http://search.cpan.org/perldoc?TinyAuth';
	}

	# Set the CGI object
	unless ( _INSTANCE($self->cgi, 'CGI') ) {
		$self->{cgi} = CGI->new;
	}

	# Determine the action
	unless ( $self->action ) {
		$self->{action} = $self->cgi->param('a') || '';
	}

	# Check for htpasswd and shadow values
	unless ( $self->auth_htpasswd ) {
		Carp::croak("No auth_htpasswd config value provided");
	}
	unless ( $self->auth_htshadow ) {
		Carp::croak("No auth_htshadow config value provided");
	}

	# Set the base arguments
	$self->{args} ||= {
		CLASS    => ref($self),
		VERSION  => $self->VERSION,
		HOMEPAGE => $self->homepage,
		DOCTYPE  => $self->html__doctype,
		HEAD     => $self->html__head,
		TITLE    => $self->title,
		HOME     => $self->html__home,
	};

	# Create the htpasswd shadow
	$self->{auth} = Apache::Htpasswd::Shadow->new(
		
	return $self;
}

sub args {
	return { %{$_[0]->{args}} };
}





#####################################################################
# Main Methods

sub run {
	my $self = shift;
	if ( $self->action eq 'f' ) {
		return $self->view_forgot;
	} elsif ( $self->action eq 'c' ) {
		return $self->view_change;
	} elsif ( $self->action eq 'n' ) {
		return $self->view_new;
	} else {
		return $self->view_index;
	}
}





#####################################################################
# Views

sub view_index {
	my $self = shift;
	$self->print_template(
		$self->html_front,
	);
	return 1;
}

sub view_forgot {
	my $self = shift;
	$self->print_template(
		$self->html_forgot,
	);
	return 1;
}

sub view_change {
	my $self = shift;
	$self->print_template(
		$self->html_change,
	);
	return 1;
}





#####################################################################
# Support Functions

sub print {
	my $self = shift;
	if ( defined $self->header ) {
		# Show the page header if this is the first thing
		CORE::print( $self->header );
		$self->{header} = undef;
	}
	CORE::print( @_ );
}

sub template {
	my $self = shift;
	my $html = shift;
	my $args = shift || $self->args;
	foreach ( 0 .. 10 ) {
		# Allow up to 10 levels of recursion
		$html =~ s/\[\%\s+(\w+)\s+\%\]/$args->{$1}/g;
	}
	return $html;
}

sub print_template {
	my $self = shift;
	$self->print(
		$self->template( @_ )
	);
	return 1;
}





#####################################################################
# Pages





sub html__doctype { <<'END_HTML' }
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
END_HTML





sub html__head { <<'END_HTML' }
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>[% TITLE %]</title>
</head>
END_HTML










sub html__home { <<'END_HTML' }
<p><a href="?a=i">Back to the main page</a></p>
END_HTML





sub html_front { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>User</h2>
<p><a href="?a=f">I forgot my password</a></p>
<p><a href="?a=c">I want to change my password</a></p>
<h2>Admin</h2>
<p><a href="?a=n">I want to add a new account</a></p>
<p><a href="?a=l">I want to see all the accounts</a></p>
<hr>
<p><i>Powered by <a href="http://search.cpan.org/perldoc?TinyAuth">TinyAuth</a></i></p>
</body>
</html>
END_HTML





sub html_forgot { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>You don't know your password</h2>
<form name="f" action="">
<input type="hidden" name="a" value="r"
<p>I can't tell you what your current password is, but I can send you a new one.</p>
<p>&nbsp;</p>
<p>What is your email address? <input type="text" name="e" size="30"> <input type="submit" name="s" value="Email me a new password"></p>
</form>
<p>&nbsp;</p>
<hr>
[% HOME %]
</body>
</html>
END_HTML





sub html_change { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>You want to change your password</h2>
<p>I just need to know a few things to do that</p>
<form name="f">
<table border="0" cellpadding="0" cellspacing="0">
<tr><td>
<p>What is your email address?</p>
<p>What is your current password?</p> 
<p>Type in the new password you want&nbsp;&nbsp;</p>
<p>Type it again to prevent mistakes</p>
</td><td>
<p><input type="text" name="e" size="30"></p>
<p><input type="text" name"p" size="30"></p>
<p><input type="text" name"n" size="30"></p>
<p><input type="text" name"c" size="30"></p>
</td></tr>
</table>
<p>Hit the button when you are ready to go <input type="submit" name="s" value="Change my password now"></p>
</form>
<hr>
[% HOME %]
<script language="JavaScript">
document.f.e.focus();
</script>
</body>
</html>
END_HTML





sub html_new { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>You don't know your password :(</h2>
<form name="f" action="">
<input type="hidden" name="a" value="r"
<p>I can't tell you what your current password is, but I can send you a new one.</p>
<p>&nbsp;</p>
<p>What is your email address? <input type="text" name="e" size="30"> <input type="submit" name="s" value="Email me a new password"></p>
</form>
<p>&nbsp;</p>
<hr>
[% HOME %]
<script language="JavaScript">
document.f.e.focus();
</script>
</body>
</html>
END_HTML

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TinyAuth>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<CGI::Capture>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
