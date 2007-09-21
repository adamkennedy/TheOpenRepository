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
	$VERSION = '0.90';
}

use Object::Tiny qw{
	config_file
	config
	cgi
	auth
	mailer
	user
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
		unless ( -w $self->htpasswd ) {
			Carp::croak("No permission to write htpasswd file");
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

	# Apply security policy
	if ( $self->cgi->param('_e') or $self->cgi->param('_p') ) {
		$self->{user} = $self->authenticate(
			$self->cgi->param('_e'),
			$self->cgi->param('_p'),
		);
		unless ( $self->is_user_admin($self->{user}) ) {
			$self->{action} = 'error';
			$self->{error}  = 'Only administrators are allowed to do that';
		}
	} elsif ( $self->cgi->cookie('e') and $self->cgi->cookie('p') ) {
		$self->{user} = $self->authenticate(
			$self->cgi->cookie('e'),
			$self->cgi->cookie('p'),
		);
		unless ( $self->is_user_admin($self->{user}) ) {
			$self->{action} = 'error';
			$self->{error}  = 'Only administrators are allowed to do that';
		}
	}

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
	if ( $self->action eq 'o' ) {
		return $self->action_logout;
	} elsif ( $self->action eq 'f' ) {
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
	} elsif ( $self->action eq 'm' ) {
		return $self->view_promote;
	} elsif ( $self->action eq 'b' ) {
		return $self->action_promote;
	} elsif ( $self->action eq 'd' ) {
		return $self->view_delete;
	} elsif ( $self->action eq 'e' ) {
		return $self->action_delete;
	} elsif ( $self->action eq 'error' ) {
		return $self->view_error( delete $self->{error} );
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

# The front page
sub view_index {
	my $self = shift;
	$self->print_template(
		$self->user
			? $self->html_index
			: $self->html_public
	);
	return 1;
}

# Login
sub action_login {
	my $self = shift;
	my $email = _STRING($self->cgi->param('_e'));
	unless ( $email ) {
		return $self->error("You did not enter an email address");
	}

	# Does the account exist
	my $user = $self->auth->lookup_user($email);
	unless ( $user ) {
		return $self->error("No account for that email address");
	}

	# Get and check the password
	my $password = _STRING($self->cgi->param('_p'));
	unless ( $password ) {
		return $self->error("You did not enter your current password");
	}
	unless ( $user->check_password($password) ) {
		sleep 3;
		return $self->error("Incorrect current password");
	}

	# Only admins can login
	$self->admins_only($user) or return 1;

	# Authenticated, set the cookies
	$self->{header} = CGI::header(
		-cookie => [
			CGI::cookie(
				-name    => 'e',
				-value   => $email,
				-path    => '/',
				-expires => '+1d',
			),
			CGI::cookie(
				-name    => 'p',
				-value   => $password,
				-path    => '/',
				-expires => '+1d',
			),
		],
	);

	# Return to the main page
	$self->view_index;
}

# Logout
sub action_logout {
	my $self = shift;

	# Set the user/pass cookies to null
	$self->{header} = CGI::header(
		-cookie => [
			CGI::cookie(
				-name    => 'e',
				-value   => '0',
				-path    => '/',
				-expires => '-1y',
			),
			CGI::cookie(
				-name    => 'p',
				-value   => '0',
				-path    => '/',
				-expires => '-1y',
			),
		],
	);

	# Clear the current user
	delete $self->{user};
	
	# Return to the index page
	return $self->view_index;
}

# Show the "I forgot my password" form
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
	my $self = shift;
	$self->admins_only or return 1;

	# Prepare the user list
	my @users = $self->all_users;
	my $list  = '';
	foreach my $user ( @users ) {
		my $item = $self->cgi->escapeHTML($user->username);
		if ( $self->is_user_admin($user) ) {
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

sub view_promote {
	my $self = shift;
	$self->admins_only or return 1;

	# Prepare the user list
	my @users = $self->all_users;
	my $list  = '';
	my $cgi   = $self->cgi;
	$cgi->param( a => 'm');
	foreach my $user ( @users ) {
		my $item = $self->cgi->escapeHTML($user->username);
		if ( $self->is_user_admin($user) ) {
			$item = $self->cgi->b($item);
		} else {
			$cgi->param( e => $item );
			$item = $self->cgi->a( {
				-href => $cgi->self_url,
				}, $item );
		}
		$list .= $item . $self->cgi->br . "\n";
	}

	# Show the page
	$self->{args}->{users} = $list;
	$self->print_template(
		$self->html_promote,
	);
}

sub action_promote {
	my $self = shift;
	$self->admins_only or return 1;

	# Does the account exist
	my $email = _STRING($self->cgi->param('e'));
	unless ( $email ) {
		return $self->error("You did not enter an email address");
	}
	my $user = $self->auth->lookup_user($email);
	unless ( $user ) {
		return $self->error("No account for that email address");
	}

	# We can't operate on admins
	if ( $self->is_user_admin($user) ) {
		return $self->error("You cannot control other admins");
	}

	# Thus, they exist and are not an admin.
	# So we now upgrade them to an admin.
	$user->extra_info('admin');

	# Send the promotion email
	$self->{args}->{email} = $user->username;
	$self->send_promote($user);

	# Show the "Promoted ok" page
	$self->view_message("Promoted account $email to admin");
}

sub send_promote {
	my ($self, $user) = @_;
	$self->send_email(
		to      => $user->username,
		subject => '[TinyAuth] You have been promoted to admin',
		body    => $self->template(
			$self->email_promote,
		),
	);
}

sub view_delete {
	my $self = shift;
	$self->admins_only or return 1;

	# Prepare the user list
	my @users = $self->all_users;
	my $list  = '';
	my $cgi   = $self->cgi;
	$cgi->param( a => 'e');
	foreach my $user ( @users ) {
		my $item = $self->cgi->escapeHTML($user->username);
		if ( $self->is_user_admin($user) ) {
			$item = $self->cgi->b($item);
		} else {
			$cgi->param( e => $item );
			$item = $self->cgi->a( {
				-href => $cgi->self_url,
				}, $item );
		}
		$list .= $item . $self->cgi->br . "\n";
	}

	# Show the page
	$self->{args}->{users} = $list;
	$self->print_template(
		$self->html_delete,
	);
}

sub action_delete {
	my $self = shift;
	$self->admins_only or return 1;

	# Does the account exist
	my $email = _STRING($self->cgi->param('e'));
	unless ( $email ) {
		return $self->error("You did not enter an email address");
	}
	my $user = $self->auth->lookup_user($email);
	unless ( $user ) {
		return $self->error("No account for that email address");
	}

	# We can't operate on admins
	if ( $self->is_user_admin($user) ) {
		return $self->error("Admins cannot control other admins");
	}

	# Thus, they exist and are not an admin.
	# So we now delete the user.
	$self->auth->delete_user($user);

	# Show the "Deleted ok" page
	$self->view_message("Deleted account $email");
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
	my $user  = $self->authenticate(
		$self->cgi->param('e'),
		$self->cgi->param('p'),
	);

	# Check the new password
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
	my $self = shift;
	$self->admins_only or return 1;
	$self->print_template(
		$self->html_new,
	);
	return 1;
}

sub action_new {
	my $self = shift;
	$self->admins_only or return 1;

	# Get the new user
	my $email = _STRING($self->cgi->param('e'));
	unless ( $email ) {
		return $self->error("You did not enter an email address");
	}

	# Does the account exist
	if ( $self->auth->lookup_user($email) ) {
		return $self->error("That account already exists");
	}

	# Create the new password
	my $password = $self->mkpasswd;
	$self->{args}->{email}    = $email;
	$self->{args}->{password} = $password;

	# Add the user
	my $user = Authen::Htpasswd::User->new($email, $password);
	$self->auth->add_user($user);

	# Send the new user email
	$self->send_new($user);

	# Print the "added" message
	return $self->view_message("Added new user $email");
}

sub send_new {
	my ($self, $user) = @_;
	$self->send_email(
		to      => $user->username,
		subject => '[TinyAuth] Created new account',
		body    => $self->template(
			$self->email_new,
		),
	);
}

sub view_message {
	my $self = shift;
	$self->{args}->{message} = CGI::escapeHTML(shift);
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

sub is_user_admin {
	my $self = shift;
	my $user = shift;
	my $info = $user->extra_info;
	return !! ( _ARRAY($info) and $info->[0] eq 'admin' );
}

sub all_users {
	my $self = shift;
	my @list = map { $_->[0] }
		sort {
			$b->[2] <=> $a->[2] # Admins first
			or
			$a->[1] cmp $b->[1] # Then by username
		}
		map { [ $_, $_->username, $self->is_user_admin($_) ] }
		$self->auth->all_users;
	return @list;
}

sub authenticate {
	my ($self, $email, $password) = @_;

	# Check params
	unless ( defined _STRING($email) ) {
		return $self->error("Missing or invalid email address");
	}
	unless ( defined _STRING($password) ) {
		return $self->error("Missing or invalid password");
	}

	# Does the account exist
	my $user = $self->auth->lookup_user($email);
	unless ( $user ) {
		return $self->error("No account for that email address");
	}

	# Get and check the password
	unless ( $user->check_password($password) ) {
		sleep 3;
		return $self->error("Incorrect password");
	}

	return $user;
}

sub admins_only {
	my $self  = shift;
	my $admin = $_[0] ? shift : $self->{user};
	unless ( $admin and $self->is_user_admin($admin) ) {
		$self->error("Only administrators are allowed to do that");
		return 0;
	}
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




sub html_public { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>User</h2>
<p><a href="?a=f">I forgot my password</a></p>
<p><a href="?a=c">I want to change my password</a></p>
<h2>Admin</h2>
<form method="post" name="f" action="">
<p><input type="text" name="_e" size="30"> Email</p>
<p><input type="text" name="_p" size="30"> Password</p>
<p><input type="submit" name="s" value="Login"></p>
</form>
<hr>
<p><i>Powered by <a href="http://search.cpan.org/perldoc?TinyAuth">TinyAuth</a></i></p>
</body>
</html>
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
<p><a href="?a=d">I want to delete an account</a></p>
<p><a href="?a=m">I want to promote an account to admin</a></p>
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
<input type="hidden" name="a" value="r">
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
<form method="post" name="f">
<input type="hidden" name="a" value="p">
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





sub html_promote { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>Click to Promote Account</h2>
[% users %]
</body>
</html>
END_HTML





sub html_delete { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>Click to Delete Account</h2>
[% users %]
</body>
</html>
END_HTML





sub html_new { <<'END_HTML' }
[% DOCTYPE %]
<html>
[% HEAD %]
<body>
<h2>Admin - Add a new user</h2>
<form method="post" name="f">
<input type="hidden" name="a" value="a">
<p>Email <input type="text" name="e" size="30"></p>
<p><input type="submit" name="s" value="Add New User"></p>
</form>
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





sub email_new { <<'END_TEXT' }
Hi

A new account has been created for you

Email:    [% email %]
Password: [% password %]

Have a nice day!
END_TEXT





sub email_promote { <<'END_TEXT' }
Hi

Your account ([% email %]) has been promoted to an administrator.

You can now login to TinyAuth to get access to additional functions.

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
