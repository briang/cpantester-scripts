#!/usr/local/bin/perl

use 5.010;

use strict;
use warnings FATAL => 'all';
#use diagnostics;

use Data::Dump;
#use Carp qw();

$|=1;
################################################################################
my $DIR = "cpanpm/distroprefs";
my $SRC = "/home/test/$DIR/10.my-stuff.yml";
my @TESTERS = (
    "bri\@lappy",
    "test\@fbsd",
);

for (@TESTERS) {
    my $cmd = "scp $SRC $_:$DIR";
    say $cmd;
    system(split ' ', $cmd) == 0
      or die "  ERROR: command failed: $?";
}
