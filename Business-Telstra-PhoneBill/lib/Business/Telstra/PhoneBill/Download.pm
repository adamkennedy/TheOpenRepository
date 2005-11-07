package Business::Telstra::PhoneBill::Download;

use 5.006001;
use strict;
use warnings;
use WWW::Mechanize;
use HTTP::Cookies;

our $VERSION = '0.01';

sub new{
  my ($class,%args) = @_;
  
  my $self = {Error    => '',
              User     => '',
              Password => '',
              Data     => '',
              Account  => 1,
              };
  
  bless $self,$class;
  
  $self->{User}     = $args{-user}     if(exists $args{-user});
  $self->{Password} = $args{-password} if(exists $args{-password});
  $self->{Account}  = $args{-account}  if(exists $args{-account} 
                                              && $args{-account} =~ /^\d+$/);
  
  return $self;
}# new

sub download{
  my ($self,%args) = @_;
  my $return_value = 0;
  
  $self->{User}     = $args{-user}     if(exists $args{-user});
  $self->{Password} = $args{-password} if(exists $args{-password});
  $self->{Account}  = $args{-account}  if(exists $args{-account}
                                              && $args{-account} =~ /^\d+$/);
  
  my $login     = $self->_login();
  $return_value = 1 if($login);
  
  return $return_value;
}# download

sub save_as{
  my ($self,$filename) = @_;
  my $return_value = 0;
  if($filename){
    if(open(my $fh,">$filename")){
      binmode $fh;
      print $fh $self->{Data};
      if(close $fh){
        $return_value = 1;
      }
    }
  }
}# save_as

sub data{
  my ($self) = @_;
  return $self->{Data};
}# data

sub user{
  my ($self,$user) = @_;
  $self->{User} = $user if(defined $user);
}# user

sub error{
  my ($self) = @_;
  return $self->{Error};
}# error

sub password{
  my ($self,$password) = @_;
  $self->{Password} = $password if(defined $password);
}# password

sub account{
  my ($self,$account) = @_;
  $self->{Account} = $account if(defined $account && $account =~ /^\d+$/);
}# account

sub _login{
  my ($self) = @_;
    print "_login...";
  $self->{Cookie_jar} = HTTP::Cookies->new();
  
  my $user       = $self->{User};
  my $pwd        = $self->{Password};
  my $url        = _get_URL($user,$pwd); 
  my $target     = 'https://telstra.com/siteminderagent/SMLogin/postCIBSLogin.do';
  my $mechanizer = WWW::Mechanize->new(autocheck => 1);
  
  $mechanizer->cookie_jar($self->{Cookie_jar});
  # necessary to get the cookie values
  $mechanizer->get($url);
  print "got first url\n";
  # real login
  $mechanizer->submit_form(fields => {
                                     user         => $user, 
                                     password     => $pwd,
                                     TARGET       => $target,
                                     SMAUTHREASON => 0,
                                     });
  print "got second url\n";
  $mechanizer->follow_link(text_regex => qr/Online Bill/);
  print "got third url\n";
  my $linkref             = $mechanizer->find_all_links(text_regex => qr/View Bill/);
  my $account             = ($self->{Account} -1) * 2;
  print $account," >> ",scalar(@$linkref),"\n";
  my $link                = $linkref->[$account];
  my $view_url            = $link->url();
  my ($doc_id,$ddn,$site) = _parse_URL($view_url);
  my $down_url            = _get_download_URL($doc_id,$ddn,$site);
  
  $mechanizer->get($down_url);
  print "downloaded csv";
  $self->{Data} = $mechanizer->content();
}# _login

sub _get_download_URL{
  my ($doc,$ddn,$site) = @_;
  my $flexcab_url = 'https://onlinebilling.telstra.com.au/postbill/'.$site;
  $flexcab_url   .= '?app=UserMain&jsp=/app/jsp/PresentCSV.jsp&viewName=AFCSVDownLd&ddn='.$ddn;
  $flexcab_url   .= '&viewType=HTML&docId='.$doc;
  
  
  my $mnet_url = 'https://onlinebilling.telstra.com.au/postbill/'.$site;
  $mnet_url   .= '?app=UserMain&jsp=/app/jsp/PresentCSV.jsp&viewName=AMCSVDownLd&ddn='.$ddn;
  $mnet_url   .= '&viewType=HTML&docId='.$doc;
  
  my $download_url = $ddn eq 'MNET_Post' ? $mnet_url : $flexcab_url;
  
  return $download_url
}# _get_download_URL

sub _parse_URL{
  my ($url) = @_;
  my ($ddn,$doc,$site) = $url =~ /\('(.*?)','(.*?)','(.*?)'/;
  return ($doc,$ddn,$site);
}# _parse_url

sub _get_URL{
  my ($user,$password) = @_;
  
  my $url = 'https://telstra.com/siteminderagent/SMLogin/preLogin.do?SMSESSION=NO';
  $url   .= '&user='.$user.'&password='.$password.'&target=&smauthreason=0&';
  $url   .= 'error_target=https://register.telstra.com.au/login/TocTraLoginError.html&';
  $url   .= 'final_target=$SM$https://shopfront.telstra.com.au/bizonline/reg.htm&';
  $url   .= 'postpreservationdata=&generallogondata=SMLogonVersion=1.0&Debug=false&';
  $url   .= 'Referer=https://register.telstra.com.au/login/TocTraLogin.html?TYPE=3353&';
  $url   .= 'REALMOID=06-def45&GUID=&SMAUTHREASON=0&';
  $url   .= 'TARGET=$SM$https://shopfront.telstra.com.au/bizonline/reg.htm';
  $url   .= '&SMIDENTITY=QUERY';
  
  return $url;
}# _get_URL


# Preloaded methods go here.

1;
__END__

=head1 NAME

Business::Telstra::PhoneBill::Download - Download phone bills from Telstra site
(CSV-files)

=head1 SYNOPSIS

  use Business::Telstra::PhoneBill::Download;
  my $download = Business::Telstra::PhoneBill::Download->new();
  
  $download->user($user);
  $download->password($password);
  $download->account($account_nr);
  $download->download();
  
  $download->save_as('download.csv');

=head1 DESCRIPTION

C<Business::Telstra::PhoneBill::Download> allows to automate the download of
Telstra PhoneBills as CSV-files.

=head1 METHODS

=head2 new([-user => $user[, -password => $pwd[, -account => $account_nr]]])

=head2 download([-user => $user[, -password => $pwd[, -account => $account_nr]]])

=head2 data()

=head2 save_as($filename)

=head2 user($user)

=head2 password($password)

=head2 account($account_nr)

=head1 REQUIREMENTS

  WWW::Mechanize
  HTTP::Cookies

=head1 ACKNOWLEDGEMENTS

Thanks to Adam Kennedy and Phase-N Australia

=head1 AUTHOR

Renee Baecker, E<lt>module@renee-baecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Renee Baecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
