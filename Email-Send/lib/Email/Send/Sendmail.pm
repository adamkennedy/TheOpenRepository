package Email::Send::Sendmail;
# $Id: Sendmail.pm,v 1.5 2006/01/17 22:10:55 cwest Exp $
use strict;

use Return::Value;

use vars qw[$SENDMAIL $VERSION];
$SENDMAIL ||= q[sendmail];

$VERSION   = '2.02';

sub is_available {
    return   `which $SENDMAIL`
           ? success
           : failure;
}

sub send {
    my ($class, $message, @args) = @_;
    open SENDMAIL, "| $SENDMAIL -t -oi @args" or return failure;
    print SENDMAIL $message->as_string;
    close SENDMAIL;
    return success;
}

1;

__END__

=head1 NAME

Email::Send::Sendmail - Send Messages using sendmail

=head1 SYNOPSIS

  use Email::Send;

  Email::Send->new({mailer => 'Sendmail'})->send($message);

=head1 DESCRIPTION

This mailer for C<Email::Send> uses C<sendmail> to send a message. It
I<does not> try hard to find the executable. It just calls
C<sendmail> and expects it to be in your path. If that's not the
case, or you want to explicitly define the location of your executable,
alter the C<$Email::Send::Sendmail::SENDMAIL> package variable.

  $Email::Send::Sendmail::SENDMAIL = '/usr/sbin/sendmail';

Any arguments passed to C<send> will be passed to C<sendmail>. The
C<-t -oi> arguments are sent automatically.

=head1 SEE ALSO

L<Email::Send>,
L<perl>.

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2004 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
