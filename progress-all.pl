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

my $FIND_LS = '/mirrors/cpan/indices/find-ls.gz';
my %SMOKERS = (
    fbsd   => 'test@fbsd',
    laptop => 'bri@lappy',
    zippy  => 'test@localhost',
);

my %find_ls = read_find_ls($FIND_LS);

for my $smoker (sort keys %SMOKERS) {
    my $current  = get_dist_under_test($smoker);
    my $ts       = $find_ls{$current};

    printf "%-6s %s %s\n", $smoker, $ts, $current;
}

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
    die $stderr if $stderr;

    return (split ' ', $stdout)[0];
}
