#!/usr/bin/perl
#############################################################################
### Author:      Wanja Chresta
### Purpose:     Writing Makefile for installing pce on GNU/Linux
### Created:     08.04.2005
### Copyright:   (c) Wanja Chresta
### Licence:     GPL
##############################################################################
use strict;
use warnings;

__PACKAGE__->new()->main();

sub new {
    my $class = shift;
    my $self = bless {}, ref $class || $class;
    return $self;
}

sub usage {
    die 
"Makefile.PL for pce, Copyright (C)  2005  Wanja Chresta
Makefile.PL for pce comes with ABSOLUTELY NO WARRANTY. 
This is free software, and you are welcome to redistribute 
it under certain conditions.

usage: perl Makefile.PL [options]
options:
    --PREFIX=<dir>
        Gibt das Prefix für die anderen Verzeichnisse an.
        Standard: /usr/local
    --NAME=<programm name>
        Name des Pakets. Standard: pce
    --BINARY=<dir>
        Installationsort für den Starter.
        Standard: <prefix>/bin/<name>
    --LIBIDR=<dir>
        Installationsverzeichnis für die Module.
        Standard: <prefix>/lib/<name>
    --SHAREDIR=<dir>
        Installationsverzeichnis für die Helpfiles.
        Standard: <prefix>/share/<name>
    --CONFDIR=<dir>
        Installationsverzeichnis der Systemkonfiguration
        Standard: /usr/local/etc/<name>

Strings in eckigen Klammern <foo> werden durch den Wert
der entsprechenden Option ersetzt.
";
}

sub main {
    my $self = shift;

    $self->init;
    $self->check_depencies;
    $self->configure_starter;
    $self->write_makefile;
}

sub init {
    my $self = shift;

    $| = 1;
    $self->config_init;
    $self->config_parse_args;
    $self->config_finish;
}

sub config_init {
    my $self = shift;

    $self->{conf} = {
        dirs => {
            prefix      => '/usr/local',
            name        => 'pce',
            libdir      => '<prefix>/lib/<name>',
            sharedir    => '<prefix>/share/<name>',
            binary      => '<prefix>/bin/<name>',
            confdir     => '/usr/local/etc/<name>',
        },
        createdirs => [ qw( libdir sharedir confdir ) ],
        install => {
            './pce.ed'      => 'binary',
            './src/pce.pm'  => 'libdir',
            './src/pce/'    => 'libdir',
            './config/*'    => 'confdir',
            './help/'       => 'sharedir',
        },
        uninstall => {
            '<binary>'        => undef,
            '<libdir>'        => './src',
            '<confdir>'       => './config',
            '<sharedir>/help' => './help',
        }
    };

    $self->{depencies} = {
            modules => [ 
            'Wx',
            'Wx::STC',
            'Wx::DND',
            'Wx::XRC',
            'Wx::Grid',
            'Config::General',
            'Hash::Merge', 
            'File::Copy',
            'File::Copy::Recursive',
        ],
    };

}

sub config_parse_args {
    my $self = shift;
    
    $_ = join ' ', @ARGV;

    /-h/                    and usage();
    /--PREFIX=(\S+)/        and $self->{conf}{dirs}{prefix}   = $1;
    /--NAME=(\S+)/          and $self->{conf}{dirs}{name}     = $1;
    /--BINARY=(\S+)/        and $self->{conf}{dirs}{binary}   = $1;
    /--LIBDIR=(\S+)/        and $self->{conf}{dirs}{libdir}   = $1;
    /--SHAREDIR=(\S+)/      and $self->{conf}{dirs}{sharedir} = $1;
    /--CONFDIR=(\S+)/       and $self->{conf}{dirs}{confdir}  = $1;
}

sub config_finish {
    my $self = shift;

    foreach my $option (keys %{$self->{conf}{dirs}}) {
        $self->{conf}{dirs}{$option} =~ s#<(.+?)>#$self->{conf}{dirs}{$1}#ge;
    }

    foreach my $option (keys %{$self->{conf}{uninstall}}) {
        my $dir = $option;
        $dir =~ s#<(.+?)>#$self->{conf}{dirs}{$1}#ge;
        $self->{conf}{uninstall}{$dir} = $self->{conf}{uninstall}{$option};
        delete $self->{conf}{uninstall}{$option};
    }
}


###

sub check_depencies {
    my $self = shift;
    
    foreach my $module (@{$self->{depencies}{modules}}) {
        print "check for Module $module... ";
        eval("require $module");
        if ($@) {
            die "\nseems that $module is not installed!\nFAILED\n\n".
                "Please install module $module eather with a package of your\n".
                "distribution or compile it by yourself with PPM and try again.\n";
        }
        print "ok\n";
    }
}

###

sub configure_starter {
    my $self = shift;
    
    my %options = (
        name     => $self->{conf}{dirs}{name},
        libdir   => $self->{conf}{dirs}{libdir},
        sharedir => $self->{conf}{dirs}{sharedir},
        confdir  => $self->{conf}{dirs}{confdir},
    );
    
    open STARTER,     "src/pce.pl" or die $!;
    open NEW_STARTER, "> pce.ed" or die $!;

    my $mode = 0;
    while (<STARTER>) {
        $_ or print STARTER $_ and next;
        
        $mode < 1 and /#Makefile.PL configuration:/    and $mode = 1 and next;
        $mode < 2 and /#Makefile.PL configuration end/ and $mode = 2 and next;

        $mode == 1 and s/<(\S+)>/$options{$1}/eg;

        print NEW_STARTER $_;
    }

    close NEW_STARTER;
    close STARTER;

    chmod 0755, 'pce.ed';
}

###

sub calc_uninstall {
    my $self = shift;
    my @dirs = @_;
   
    my %uninstall = %{$self->{conf}{uninstall}};
    my (@files, @del_dirs);
    
    eval 'require File::Find;';
    unless ($@) {
        foreach my $dir (keys %uninstall) {
            if ($uninstall{$dir}) {
                push @del_dirs, $dir;
            } else {
                push @files, $dir;
                next;
            }
 
            File::Find::find({
                no_chdir => 1,
                wanted => sub {
                    return unless $File::Find::name;

                    my $file = $File::Find::name;
                    $file =~ s~^$uninstall{$dir}~~;
                    return unless $file;
                    
                    if (-d $File::Find::name) {
                        push @del_dirs, "$dir$file";
                    } else {
                        push @files, "$dir$file";
                    }
                }},
                $uninstall{$dir});
        }
    } else {
        print "\nDidn't find File::Find. Not writing uninstall section\n";
    }

    $self->{data}{to_delete}{files} = \@files;
    $self->{data}{to_delete}{dirs}  = \@del_dirs;
}

sub write_makefile {
    my $self = shift;

    print "Looks good. Writing Makefile... ";

    my %dirs      = %{$self->{conf}{dirs}};
    my %install   = %{$self->{conf}{install}};
    
    # Calculating paths of installed files for uninstall
    $self->calc_uninstall(keys %install);

    my @to_delete_files = @{$self->{data}{to_delete}{files}};
    my @to_delete_dirs  = @{$self->{data}{to_delete}{dirs}};

    open MAKEFILE, '> Makefile'
        or die $!;

    #
    print MAKEFILE qq~$_ = "$dirs{$_}"\n~ foreach (keys %dirs);

    print MAKEFILE "\ninstall:\n"; 
    print MAKEFILE qq~\tinstall -d \$($_)\n~          foreach (@{$self->{conf}{createdirs}});
    print MAKEFILE qq~\tcp -a $_ \$($install{$_})\n~  foreach (keys %install);

    print MAKEFILE "\nuninstall:\n" if (@to_delete_files > 0);
    print MAKEFILE qq~\trm -f $_\n~   foreach (@to_delete_files);
    print MAKEFILE qq~\trmdir --ignore-fail-on-non-empty $_\n~   foreach (sort {$b cmp $a} @to_delete_dirs);
    
    print MAKEFILE qq~\nclean:\n\trm pce.ed Makefile\n~;
    
    close MAKEFILE;

    print "done\nYou may now install pce with 'make install'\n";
}

1;

