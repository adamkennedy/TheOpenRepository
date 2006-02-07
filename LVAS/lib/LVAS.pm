package LVAS;

# See POD at end for docs

use 5.005;
use strict;
use IO::Socket::SSL;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub new {
	my ($package, $date) = @_;
	my $self = bless {}, $package;

	$self->{client} = undef;
	$self->{state} = 'I';
	
	return $self;
}

# Internal use

sub response_invalid {
	my ($self, $rcode, $rmsg) = @_;
	die "ERROR: Invalid response received: $rcode | $rmsg";
}

sub send_command {
	my ($self, $command) = @_;
	die "Not connected to server" if $self->{state} eq 'I';
	$realcmd = $command . "\r\n";
	#print "--> $realcmd";
	$self->{client}->print($realcmd);
}

sub read_response {
	my $self = shift;
	$line = $self->{client}->getline();
	chomp $line;
	#print "<-- $line\r\n";
	$line =~ s/\r//g;
	if ($line =~ /^(\d{3})\s(.+)$/) {
		return ($1, $2);
	} else {
		die "Malformed response message received from LVAS server";
	}
}

sub read_response_check_success {
	my ($self, $rcode_success) = @_;
	
	my ($rcode, $rmsg) = $self->read_response;

	if ($rcode eq $rcode_success) {
		return 1;
	} else {
		warn $rmsg;
		return 0;
	}
}

sub read_tabular_response {
	my ($self, $exp_rcode, $exp_col) = @_;
	my @result;
	while (($rcode, $rmsg) = $self->read_response()) {
		if ($rcode eq '100') {
			warn "Invalid command sent to server";
			return undef;
		} elsif ($rcode eq $exp_rcode) {
			my @bits = split(/"\s*"/, $rmsg);
			$bits[0] =~ s/^"//;
			$bits[@bits - 1] =~ s/"$//;
			push @result, \@bits;
		} elsif ($rcode eq '350' || $rcode eq '351') {
			foreach $ent (@results) {
				warn "Column counts did not match expected value" && return undef if @$ent+0 != $exp_col;
			}
			last;
		}
	}
	return @result;
}

sub connect {
	my ($self, $host, $port) = @_;

	$self->{client} = new IO::Socket::SSL("$host\:$port");
	
	if (!defined $self->{client}) {
		warn "LVAS connection to $host\:$port failed: " . IO::Socket::SSL::errstr();
		return 0;
	}
		
	my ($rcode, $rmsg) = $self->read_response;

	if ($rcode ne '500') {
		warn "Connection failed: Invalid connection response code $rcode";
		return 0;
	}

	#print "SERVER: " . $rmsg . "\n";
	$self->{state} = 'C';
	return 1;

}

sub authenticate {
	my ($self, $handle, $password) = @_;

	$self->send_command("CONTACT AUTHENTICATE $handle $password");

	my ($rcode, $rmsg) = $self->read_response;

	if ($rcode eq '300') {
		$self->{state} = 'A';
		return 1;
	} elsif ($rcode eq '200') {
		return 0;
	} else {
		$self->response_invalid($rcode,$rmsg);
	}
}

# Command wrappers

sub locate_vserver {
	my ($self, $hostname) = @_;
	@list = $self->list_vservers;
	foreach $ent (@list) {
		if ($ent->[1] eq $hostname) {
			return $ent->[0];
		}
	}
	return undef;
}

sub locate_domain {
	my ($self, $domain) = @_;
	@list = $self->list_domains;
	foreach $ent (@list) {
		if ($ent->[1] eq $domain) {
			return $ent->[0];
		}
	}
	return undef;
}

sub list_vservers {
	my $self = shift;
	die "Not authenticated with server" if $self->{state} ne 'A';
	$self->send_command('LIST VSERVERS');
	return $self->read_tabular_response(601, 2);
}

sub list_domains {
	my $self = shift;
	die "Not authenticated with server" if $self->{state} ne 'A';
	$self->send_command('LIST DOMAINS');
	return $self->read_tabular_response(650, 2);
}

sub vserver_list_mail_accounts {
	my ($self, $vserver_id) = @_;
	die "Not authenticated with server" if $self->{state} ne 'A';
	$self->send_command("VSERVER $vserver_id LIST MAIL ACCOUNTS");
	return $self->read_tabular_response(603, 3);
}

sub vserver_list_mail_aliases {
	my ($self, $vserver_id) = @_;
	die "Not authenticated with server" if $self->{state} ne 'A';
	$self->send_command("VSERVER $vserver_id LIST MAIL ALIASES");
	return $self->read_tabular_response(602, 4);
}

sub vserver_create_local_mail_alias {
	my ($self, $vserver_id, $dns_id, $alias, $mailbox) = @_;
	die "Not authenticated with server" if $self->{state} ne 'A';
	$self->send_command("VSERVER $vserver_id CREATE LOCAL MAIL ALIAS $dns_id $alias $mailbox");
	return $self->read_response_check_success(350);
}

sub vserver_create_remote_mail_alias {
	my ($self, $vserver_id, $dns_id, $alias, $addr) = @_;
	die "Not authenticated with server" if $self->{state} ne 'A';
	$self->send_command("VSERVER $vserver_id CREATE REMOTE MAIL ALIAS $dns_id $alias $addr");
	return $self->read_response_check_success(350);
}

sub vserver_remove_mail_alias {
	my ($self, $vserver_id, $dns_id, $alias) = @_;
	die "Not authenticated with server" if $self->{state} ne 'A';
	$self->send_command("VSERVER $vserver_id REMOVE MAIL ALIAS $alias $dns_id");
	return $self->read_response_check_success(350);
}

sub disconnect {
	my $self = shift;
	$self->send_command('EXIT');
	close $self->{client};
	$self->{state} = 'I';
}

1;

__END__

=pod

=head1 NAME

LVAS - Client interface for the LVAS daemon

=head1 SYNOPSIS

  Example code here

TO BE COMPLETED

=head1 DESCRIPTION

This is the client interface to the LVAVD daemon.

TO BE COMPLETED

=head1 METHODS

=head2 new

  my $lvas = LVAS->new( ... );

The C<new> constructor ...

TO BE COMPLETED

=head2 etc

ETC

=head1 SUPPORT

Contact the author.

=head1 AUTHOR

Patrick Cole <z@amused.net>

=head1 COPYRIGHT

Copyright 2005, 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
