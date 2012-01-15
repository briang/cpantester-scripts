#!/usr/local/bin/perl

use 5.010;

use strict;
use warnings FATAL => 'all';
#use diagnostics;

use Data::Dump;
#use Carp qw();

$|=1;
################################################################################
package Dist;
use Moose;
use MooseX::StrictConstructor;

has [ qw( cpanid dist distvname extension filename maturity
          relpath ) ] => qw(is ro isa Str        required 1);
has [ qw( version ) ] => qw(is ro isa Maybe[Str] required 1);
################################################################################
package main;
use autodie;

use CPAN::DistnameInfo;
use PerlIO::gzip;

use constant CPAN_MIRROR       => '/mirrors/cpan';
use constant FIND_LS           => CPAN_MIRROR . '/indices/find-ls.gz';
#use constant FIND_LS           => 'find-ls.gz';
use constant UNWANTED_DISTS_RE => qr{
    ^(?:
    .^   # never matches, only purpose is to let things align nicely
    # CPAN

    |ADAMK/CPAN-Index-0.01.tar.gz
    |ANDK/CPAN-1\.9304\.tar\.gz
    |ANDK/CPAN-1\.9402\.tar\.gz

    # ShipIt

    |.*/ShipIt-

    # more blockers

    |GSEAMAN/XML-DB.tar.gz                                        # repeated prompts
    |MAKAMAKA/JSON-PPdev-2.27100.tar.gz                           # old JSON::PP
    |TURNSTEP/Net-SSH-Perl-1.34.tar.gz
    |HINRIK/IO-WrapOutput-0.07.tar.gz                             # hangs
    |BARBIE/CPAN-Testers-WWW-Reports-Mailer-0.27.tar.gz           # hangs
    |ZEFRAM/DateTime-TimeZone-Tzfile-0.006.tar.gz                 # hangs
    |AGRUNDMA/POE-Loop-EV-0.06.tar.gz                             # hangs
    |MJD/Net-DHCP-Control-0.09.tar.gz                             # prompts
    |BTROTT/XML-FOAF-\d
    |ZOFFIX/POE-Component-Data-SimplePassword-0.0101.tar.gz
    |ZOFFIX/POE-Component-IRC-Plugin-Data-SimplePassword-0.0101.tar.gz
    |ZEFRAM/DateTime-TimeZone-Olson-0.002.tar.gz                  # hangs
    |VIPUL/Crypt-RSA-1.96.tar.gz                                  # hangs
    |BARBIE/CPAN-Testers-WWW-Reports-Mailer-0.27.tar.gz           # hangs
    |LDS/Bio-BigFile-1.06.tar.gz                                  # prompts
    |MJD/Net-DHCP-Control-0.09.tar.gz                             # prompts
    |LDS/Bio-BigFile-1.06.tar.gz                                  # prompts
    |BARBIE/CPAN-Testers-WWW-Reports-Mailer-0.27.tar.gz           # hangs
    |SDPRICE/Linux-DVB-
    |AMD/Tapper-
    |FLORA/Module-Signature-0.68.tar.gz
    |KAL/Lingua-StanfordCoreNLP-\d                                # 191MB !!!
    |DSTAAL/Term-Menus-FromFile-\d
    |REEDFISH/Term-Menus-\d
    |MAKAMAKA/JSON-1                                              # need higher version
    |MAKAMAKA/JSON-PP-2.271                                       # need higher version
    |DROLSKY/Alzabo-GUI-Mason-0.1201.tar.gz                       # repeated prompts
    |KANE/IPC-Cmd-0.22.tar.gz                                     # need higher version
    |RPAUL/LWP-Protocol-virtual-0.02.tar.gz                       # prompts
    |SEGAN/POE-Component-LaDBI-1.2.1.tar.gz

    |AMALTSEV/XAO-Catalogs-1.02.tar.gz
    |AMALTSEV/XAO-Commerce-1.02.tar.gz
    |AMALTSEV/XAO-Content-1.02.tar.gz
    |AMALTSEV/XAO-ImageCache-1.tar.gz
    |AMALTSEV/XAO-Indexer-1.01.tar.gz
    |AMALTSEV/XAO-MySQL-1.02.tar.gz
    |AMALTSEV/XAO-PodView-1.03.tar.gz
    |AUTRIJUS/Apache-Session-SQLite3-0.03.tar.gz
    |AUTRIJUS/Perl6-Pugs-6.0.12.tar.gz
    |AWESTHOLM/Project-Gantt-1.03.tar.gz
    |BORISZ/Apache-PageKit-1.18.tar.gz
    |BOZO/Fry-Lib-CDBI-Basic-0.15.tar.gz
    |BPOSTLE/MKDoc-Apache_Cache-0.71.tar.gz
    |BPOSTLE/Petal-Mail-0.31.tar.gz
    |BPOSTLE/Petal-Parser-HTB-1.04.tar.gz
    |CDENT/Kwiki/Kwiki-DatedAnnounce-0.01.tar.gz
    |CDENT/Kwiki/Kwiki-PageTemperature-0.01.tar.gz
    |CDENT/Kwiki/Kwiki-Technorati-0.04.tar.gz
    |CDENT/Kwiki/Kwiki-Test-0.03.tar.gz
    |CLINTDW/Apache-ReverseProxy-0.07.tar.gz
    |DANPEDER/DynaPage-Apache2-0.90.tar.gz
    |DANPEDER/DynaPage-Document-0.90.tar.gz
    |DAVIDNICO/Acme/Array-Frugal-0.01.tar.gz
    |GMPASSOS/lib-http-0.01.tar.gz
    |GUGOD/Algorithm-Accounting-0.08.tar.gz
    |GUGOD/Graph-SocialMap-0.12.tar.gz
    |GUGOD/Kwiki-MindMap-0.09.tar.gz
    |GUGOD/Kwiki-NavigationToolbar-0.02.tar.gz
    |GUGOD/Kwiki-PageTemplate-0.04.tar.gz
    |GUGOD/Kwiki-Search-Plucene-0.03.tar.gz
    |GUGOD/Kwiki-Theme-ColumnLayout-0.08.tar.gz
    |GUGOD/Log-Accounting-SVK-0.05.tar.gz
    |GUGOD/SVK-Churn-0.02.tar.gz
    |ICESPIRIT/Bundle-Knetrix-1.0.tar.gz
    |INGY/Kwiki-BreadCrumbs-0.12.tar.gz
    |INGY/Kwiki-Favorites-0.13.tar.gz
    |INGY/Kwiki-GuestBook-0.13.tar.gz
    |INGY/Kwiki-PagePrivacy-0.10.tar.gz
    |INGY/Kwiki-PerlTidyBlocks-0.12.tar.gz
    |INGY/Kwiki-PerlTidyModule-0.12.tar.gz
    |INGY/Kwiki-Spork-0.11.tar.gz
    |INGY/Kwiki-UserName-0.14.tar.gz
    |INGY/Kwiki-UserPreferences-0.13.tar.gz
    |IVAN/Business-OnlinePayment-SecureHostingUPG-0.01.tar.gz
    |JABLKO/Filesys-Virtual-DPAP-0.01.tar.gz
    |JOOON/Kwiki-CoolURI-0.04.tar.gz
    |JOOON/Kwiki-DNSBL-0.01.tar.gz
    |JOOON/Kwiki-Theme-Bluepole-1.00.tar.gz
    |JOOON/Kwiki-URLBlock-0.05.tar.gz
    |JPEREGR/Kwiki-Edit-RequireUserName-0.02.tar.gz
    |JSIRACUSA/Bundle-Rose-0.02.tar.gz
    |KAKE/CGI-Wiki-Kwiki-0.59.tar.gz
    |KANE/Bundle-CPANPLUS-0.01.tar.gz
    |KCK/Gtk2-Ex-Utils-0.09.tar.gz
    |KJETILK/Apache-AxKit-Provider-File-Formatter-0.96.tar.gz
    |KWILLIAMS/Apache-SSI-2.19.tar.gz
    |LBROCARD/HTTP-Server-Simple-Kwiki-0.29.tar.gz
    |MILSO/dbMan-0.37.tar.gz
    |MSCHILLI/Acme-Prereq-A-0.01.tar.gz
    |MSCHILLI/Acme-Prereq-B-0.01.tar.gz
    |NACHBAUR/Apache-AxKit-Language-SpellCheck-0.03.tar.gz
    |OCTO/Apache-PrettyPerl-2.10.tar.gz
    |OFEYAIKON/Gtk2-Ex-RecordsFilter-0.03.tar.gz
    |PATL/File-FDkeeper-0.06.tar.gz
    |PSCHOO/Apache-ProxyConf-1.0.tar.gz
    |RCLAMP/Filesys-Virtual-DAAP-0.04.tar.gz
    |RCLAMP/Net-DPAP-Server-0.02.tar.gz
    |REID/Games-Go-GoPair-1.001.tar.gz
    |RLAUGHLIN/UDPmsg-0.11.tar.gz
    |SHANTANU/File-UStore-0.01.tar.gz
    |SIMONFLK/Wx-Perl-Throbber-1.05.tar.gz
    |SIMONFLK/Wx-Perl-TreeChecker-1.13.tar.gz
    |SIMONW/Acme-Scurvy-Whoreson-BilgeRat-Backend-insultserver-1.0.tar.gz
    |SIMONW/Bot-BasicBot-Pluggable-Module-Fun-0.9.tar.gz
    |SIMONW/Bot-BasicBot-Pluggable-Module-Network-0.9.tar.gz
    |SIMONW/Buscador-0.2.tar.gz
    |SIMONW/Email-Store-0.24.tar.gz
    |SMPETERS/Bundle-Phalanx-0.07.tar.gz
    |SMUELLER/Bundle-Math-1.02.tar.gz
    |SPEEVES/Apache-AuthenNTLM-2.10.tar.gz
    |STAS/Apache-Watchdog-RunAway-1.00.tar.gz
    |STEVAN/Bundle-Tree-Simple-0.01.tar.gz
    |SZABGAB/CPAN-Forum-0.11.tar.gz
    |TOBI/Finance-Bank-Commerzbank-0.29.tar.gz
    |TOMSON/Apache-AxKit-Provider-RDBMS-0.01.tar.gz
    |TPABA/UniLog/UniLog-0.14.tar.gz
    |TWH/Bundle-WormBase-0.001.tar.gz
    |XANTUS/POE-Component-XUL-0.02.tar.gz
    ##END

    # Stuff I'm not interested in

    |.*(?i:apache)                      # spews/interactive (XXX always???)
    |.*(?i:glib)
    |.*(?i:mod_perl)                    # tries to build apache
    |.*/Padre-                          # they all get DISCARDed
    |.*(?i:jifty)                       # broken beyond repair
    |.*/(?i:acme)-                      # waste of space
    |.*(?i:win32)                       # I have only linux
    |.*(?i:\b(gtk|tk|qt|wx))            # graphics
    |.*(?i:(gtk|tk|qt|wx)\b)            # graphics
    )
}x;

my $dists = read_file_ls();

$dists = prune_older_versions();
$dists = prune_unwanted_distvnames();

sub prune_unwanted_distvnames {
    my @new;

    for my $dist (@$dists) {
        my $author_filename = $dist->cpanid . '/' . $dist->filename;
        if ($author_filename =~ +UNWANTED_DISTS_RE) {
            say $dist->distvname, " isn't wanted";
        }
        else {
            push @new, $dist;
        }
    }
    return \@new;
}

sub prune_older_versions {
    my @new;

    my %seen;
    for my $dist (@$dists) {
        if ($seen{ $dist->dist }++) {
            say $dist->distvname, " already seen";
        }
        else {
            push @new, $dist;
        }
    }
    return \@new;
}

sub read_file_ls {
    open my $FILE_LS, "<:gzip", FIND_LS;

    my @dists;
    while (<$FILE_LS>) {
        my @fields    = split;
        my $preamble  = join ' ', @fields[0..6];
        my $timestamp = $fields[7];
        my $path      = $fields[8];

        my $di = CPAN::DistnameInfo->new($path);

        # if $path is authors/id/G/GB/GBARR/CPAN-DistnameInfo-0.02.tar.gz ...
        push @dists, Dist->new(
            cpanid    => $di->cpanid,    # "GBARR"
            dist      => $di->dist,      # "CPAN-DistnameInfo"
            distvname => $di->distvname, # "CPAN-DistnameInfo-0.02"
            extension => $di->extension, # "tar.gz"
            filename  => $di->filename,  # "CPAN-DistnameInfo-0.02.tar.gz"
            maturity  => $di->maturity,  # "released"
            relpath   => $di->pathname,  # "authors/id/G/GB/GBARR/..."
            version   => $di->version,   # "0.02"
        );
    }
    return \@dists;
}
