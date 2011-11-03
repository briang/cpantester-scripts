#!/usr/local/bin/perl

use 5.010;

use strict;
use warnings FATAL => 'all';
#use diagnostics;

use Data::Dump;
#use Carp qw();

$|=1;
################################################################################
#use Try::Tiny;
use autodie;
use Capture::Tiny qw<capture>;
use Text::Table;

my $FIND_LS = '/mirrors/cpan/indices/find-ls.gz';
my %SMOKERS = (
    fbsd   => 'test@fbsd',
    laptop => 'bri@lappy',
    zippy  => 'test@localhost',
);

my %find_ls = read_find_ls($FIND_LS);

my $tab = Text::Table->new;
for my $smoker (sort keys %SMOKERS) {
    my $current = get_dist_under_test($smoker);
    if (ref $current eq '') {
        my $ts      = $find_ls{$current};
        $tab->add($smoker, $ts, $current);
    }
    else { # error
        $$current =~ s/\r\n$//;
        $tab->add($smoker, '', "[$$current]");
    }
}

print $tab;
exit;

sub read_find_ls {
    my $fls = shift;

    open my $IN, "zcat $FIND_LS |";

    my %h;
    while (<$IN>) {
        my ($dist, $ts) = (split)[8, 7];
        s|.*/||, s/\.(?:tar\.gz|tar\.bz2|zip)$//
          for $dist;
        $h{$dist} = $ts;
    }
    return %h;
}

sub get_dist_under_test {
    my $smoker = shift;

    my @cmd = (
        'ssh', $SMOKERS{$smoker},
        q<cat `ls -t1 /tmp/smoker-status-*.txt|head -1`>
    );

    my ($stdout, $stderr) = capture { system @cmd };
    return \$stderr if $stderr;

    return (split ' ', $stdout)[0];
}
