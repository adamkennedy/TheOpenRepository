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
use File::Spec       ();
use YAML::Tiny       ();
use CGI              ();
use Params::Util     qw{ _STRING _INSTANCE _ARRAY };
use String::MkPasswd ();
use Authen::Htpasswd ();
use Email::Send      ();
use Email::Stuff     ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.05';
}

use Object::Tiny qw{
	config_file
	config
	cgi
	auth
	mailer
	action
	header
	title
	homepage
	};





#####################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Check and set the config
	unless ( _INSTANCE($self->config, 'YAML::Tiny') ) {
		Carp::croak("Did not provide a config param");
	}

	# Create the htpasswd shadow
	unless ( $self->auth ) {
		# Check for a htpasswd value
		unless ( $self->htpasswd ) {
			Carp::croak("No htpasswd file provided");
		}
		unless ( -r $self->htpasswd ) {
			Carp::croak("No permission to read htpasswd file");
		}
		$self->{auth} = Authen::Htpasswd->new( $self->htpasswd );
	}
	unless ( _INSTANCE($self->auth, 'Authen::Htpasswd') ) {
		 Carp::croak("Failed to create htpasswd object");
	}

	# Create the mailer
	unless ( $self->email_from ) {
		Carp::croak("No email_from address in config file");
	}
	unless ( $self->mailer ) {
		$self->{mailer} = Email::Send->new( {
			mailer => $self->email_driver,
			} );
	}
	unless ( _INSTANCE($self->mailer, 'Email::Send') ) {
		Carp::croak("Failed to create mailer");
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

	# Set the base arguments
	$self->{args} ||= {
		CLASS    => ref($self),
		VERSION  => $self->VERSION,
		HOMEPAGE => $self->homepage,
		TITLE    => $self->title,
		DOCTYPE  => $self->html__doctype,
		HEAD     => $self->html__head,
		HOME     => $self->html__home,
	};

	return $self;
}

sub args {
	return { %{$_[0]->{args}} };
}

sub htpasswd {
	$_[0]->config->[0]->{htpasswd};
}

sub email_from {
	$_[0]->config->[0]->{email_from};
}

sub email_driver {
	$_[0]->config->[0]->{email_driver} || 'Sendmail';
}





#####################################################################
# Main Methods

sub run {
	my $self = shift;
	if ( $self->action eq 'f' ) {
		return $self->view_forgot;
	} elsif ( $self->action eq 'r' ) {
		return $self->action_forgot;
	} elsif ( $self->action eq 'c' ) {
		return $self->view_change;
	} elsif ( $self->action eq 'p' ) {
		return $self->action_change;
	} elsif ( $self->action eq 'n' ) {
		return $self->view_new;
	} elsif ( $self->action eq 'a' ) {
		return $self->action_new;
	} elsif ( $self->action eq 'l' ) {
		return $self->view_list;
	} else {
		return $self->view_index;
	}
}

sub mkpasswd {
	String::MkPasswd::mkpasswd( -fatal => 1 );
}

sub send_email {
	my $self   = shift;
	my %params = @_;
	my $email  = Email::Stuff->new;
	$email->to(        $params{to}       );
	$email->from(      $self->email_from );
	$email->subject(   $params{subject}  );
	$email->text_body( $params{body}     );
	$email->using(     $self->mailer     );
	$email->send;
	return 1;
}





#####################################################################
# Main Methods

sub view_index {
	my $self = shift;
	$self->print_template(
		$self->html_index,
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

# Re-issue a password
sub action_forgot {
	my $self  = shift;
	my $email = _STRING($self->cgi->param('e'));
	unless ( $email ) {
		return $self->error("You did not enter an email address");
	}

	# Does the account exist
	my $user = $self->auth->lookup_user($email);
	unless ( $user ) {
		return $self->error("No account for that email address");
	}

	# Create the new password
	my $password = $self->mkpasswd;
	$user->password($password);
	$self->auth->update_user($user);
	$self->{args}->{password} = $password;

	# Send the password email
	$self->send_forgot( $user );

	# Show the "password email sent" page
	$self->view_message("Password email sent");
}

sub send_forgot {
	my ($self, $user) = @_;
	$self->send_email(
		to      => $user->username,
		subject => '[TinyAuth] Forgot Your Password',
		body    => $self->template(
			$self->email_forgot,
		),
	);
}

sub view_list {
	my $self  = shift;

	# Prepare the user list
	my @users = sort {
		$a->username cmp $b->username
		} $self->auth->all_users;
	my $list = '';
	foreach my $user ( @users ) {
		my $item = $self->cgi->escapeHTML($user->username);
		my $info = $user->extra_info;
		if ( _ARRAY($info) and $info->[0] eq 'admin' ) {
			$item = $self->cgi->b($item);
		}
		$list .= $item . $self->cgi->br . "\n";
	}

	# Show the page
	$self->{args}->{users} = $list;
	$self->print_template(
		$self->html_list,
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

sub action_change {
	my $self  = shift;
	my $email = _STRING($self->cgi->param('e'));
	unless ( $email ) {
		return $self->error("You did not enter an email address");
	}

	# Does the account exist
	my $user = $self->auth->lookup_user($email);
	unless ( $user ) {
		return $self->error("No account for that email address");
	}

	# Get and check the password
	my $password = _STRING($self->cgi->param('p'));
	unless ( $password ) {
		return $self->error("You did not enter your current password");
	}
	unless ( $user->check_password($password) ) {
		sleep 3;
		return $self->error("Incorrect current password");
	}

	# Get and check the new password
	my $new = _STRING($self->cgi->param('n'));
	unless ( $new ) {
		return $self->error("Did not provide a new password");
	}
	my $confirm = _STRING($self->cgi->param('c'));
	unless ( $confirm ) {
		return $self->error("Did not provide a confirmation password");
	}
	unless ( $new eq $confirm ) {
		return $self->error("New password and confirmation do not match");
	}

	# Set the new password
	$user->set('password' => $new);

	return $self->view_message("Your password has been changed");
}

sub view_new {
	die "CODE INCOMPLETE";
}

sub action_new {
	die "CODE INCOMPLETE";
}

sub view_message {
	my $self = shift;
	$self->{args}->{message} = shift;
	$self->print_template(
		$self->html_message,
	);
	return 1;
}

sub error {
	my $self = shift;
	$self->{args}->{error} = shift;
	$self->print_template(
		$self->html_error,
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





sub html_index { <<'END_HTML' }
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
<form method="post" name="f" action="">
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
<p>Hit the button when you are ready to go <input type="submit" name="s" value="Change my password"></p>
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





sub html_list { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>Account List</h2>
[% users %]
</body>
</html>
END_HTML





sub html_message { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h1>Action Completed</h1>
<h2>[% message %]</h2>
</body>
</html>
END_HTML





sub html_error { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h1>Error</h1>
<h2>[% error %]</h2>
</body>
</html>
END_HTML





sub email_forgot { <<'END_TEXT' }
Hi

You forgot your password, so here is a new one

Password: [% password %]

Have a nice day!
END_TEXT

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
