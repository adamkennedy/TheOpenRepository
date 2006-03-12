package Email::Send::NNTP;
# $Id: NNTP.pm,v 1.3 2006/01/17 22:10:55 cwest Exp $
use strict;

use vars qw[$NNTP $VERSION];
use Net::NNTP;
use Return::Value;
use UNIVERSAL::require;

$VERSION   = '2.02';

sub is_available {
    return   Net::NNTP->require
           ? success
           : failure;
}

sub send {
    my ($class, $message, @args) = @_;
    Net::NNTP->require;
    if ( @_ > 1 ) {
        $NNTP->quit if $NNTP;
        $NNTP = Net::NNTP->new(@args);
        return failure unless $NNTP;
    }
    return failure unless $NNTP->post( $message->as_string );
    return success;
}

sub DESTROY {
    $NNTP->quit if $NNTP;
}

1;

__END__

=head1 NAME

Email::Send::NNTP - Post Messages to a News Server

=head1 SYNOPSIS

  use Email::Send;

  my $mailer = Email::Send->new({mailer => 'NNTP'});
  
  $mailer->mailer_args([Host => 'nntp.example.com']);
  
  $mailer->send($message);

=head1 DESCRIPTION

This is a mailer for C<Email::Send> that will post a message to a news server.
The message must be formatted properly for posting. Namely, it must contain a
I<Newsgroups:> header. At least the first invocation of C<send> requires
a news server arguments. After the first declaration the news server will
be remembered until such time as you pass another one in.

=head1 SEE ALSO

L<Email::Send>,
L<Net::NNTP>,
L<perl>.

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2004 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
