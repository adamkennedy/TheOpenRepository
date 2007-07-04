package TinyAuth;

use 5.005;
use strict;
use Apache::Htpassword::Shadow ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	cgi
	action
	header
	title
	homepage
	auth_store
	auth_target
	};





#####################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Set the header
	unless ( $self->header ) {
		$self->{header} = CGI::header( 'text/html' );
	}

	# Set the page title
	unless ( $self->title ) {
		$self->{title} = 'SVN Repository Management';
	}

	# Set the homepage
	unless ( $self->homepage ) {
		$self->{homepage} = 'http://search.cpan.org/perldoc?TinyAuth';
	}

	# Determine the action
	unless ( $self->action ) {
		$self->{action} = $self->cgi->param('a') || '';
	}

	# Set the base arguments
	$self->{args} ||= {
		CLASS    => ref($self),
		VERSION  => $self->VERSION,
		HOMEPAGE => $self->homepage,
		DOCTYPE  => $self->html__doctype,
		HEAD     => $self->html__head,
		TITLE    => $self->title,
		BANNER   => $self->html__banner,
		HOME     => $self->html__home,
	};

	# Check for configuration variables
	unless ( $self->svn_
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
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
END_HTML





sub html__head { <<'END_HTML' }
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>[% TITLE %]</title>
<style type="text/css">
<!--
body {
	font-family: Verdana, Arial, Helvetica, sans-serif;
}
-->
</style>
</head>
END_HTML





sub html__banner { <<'END_HTML' }
<table width="100%%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td><strong><font size="6">[% TITLE %]</font></strong></td>
    <td align="right" valign="bottom"><font size="1"><a href="http://search.cpan.org/perldoc?[% CLASS %]">[% CLASS %] [% VERSION %]</a></font></td>
  </tr>
</table>
<hr>
END_HTML





sub html__home { <<'END_HTML' }
<p><a href="?a=i">Back to the main page</a></p>
END_HTML





sub html_front { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
[% BANNER %]
<h2>What brings you here today?</h2>
<p><a href="?a=f">I don't know my password :(</a></p>
<p><a href="?a=c">I want to change my password</a></p>
<p><a href="?a=n">I want to add a new account (and I'm an admin)</a></p>
<p><a href="?a=l">I want to see all the accounts (and I'm an admin)</a></p>
<hr>
</body>
</html>
END_HTML





sub html_forgot { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
[% BANNER %]
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





sub html_change { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
[% BANNER %]
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
[% BANNER %]
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
