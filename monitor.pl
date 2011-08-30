#!/usr/local/bin/perl

use 5.010;

use strict;
use warnings FATAL => 'all';
#use diagnostics;

use Data::Dump;
#use Carp qw();

$|=1;
################################################################################
use Try::Tiny;
use Capture::Tiny qw<capture>;

my $LOG_PERIOD   = 6 * 60;      # warn if log hasn't grown in last n seconds
my $MAX_LOG_SIZE = 100_000_000;
my $SCAN_PERIOD  = 30;          # scan every n seconds
my $DB_PERIOD    = 12 * 60;     # warn if DB hasn't grown in last n seconds

my %smokers = (
    fbsd   => { addr => '172.16.1.11', user => 'test' },
    laptop => { addr => '172.16.1.8',  user => 'bri'  },
    zippy  => { addr => 'localhost',   user => 'test' },
);

say "Monitoring ", join ", ", sort keys %smokers;

my %data;
while (1) {
    for my $smoker (keys %smokers) {
        my $db_length  = filesize($smoker, '.cpanreporter/reports-sent.db');
        my $db_prev    = $data{$smoker}{db} // -1;
        my $log_length = filesize($smoker, '.cpan/smoker.log');
        my $log_prev   = $data{$smoker}{log} // -1;

        alert("$smoker\'s log is too big")
          if $log_length > $MAX_LOG_SIZE;

        if ($log_length == $log_prev || $db_length == $db_prev) {
            alert("$smoker seems stalled (DB)")
              if time - $data{$smoker}{db_time}  >= $DB_PERIOD;
            alert("$smoker seems stalled (log)")
              if time - $data{$smoker}{log_time} >= $LOG_PERIOD;
        }
        else {
            @{$data{$smoker}}{qw<db db_time>} = ( $db_length, time )
              if $db_length != $db_prev;

            @{$data{$smoker}}{qw<log log_time>} = ( $log_length, time )
              if $log_length != $log_prev;
        }
    }
    sleep $SCAN_PERIOD;
}

sub alert {
    say @_, "\a";
    sleep 1;
}

sub filesize {
    my $smoker = shift;
    my $file   = shift;

    my @cmd = (
        'ssh',
        sprintf( q<%s@%s>, @{$smokers{$smoker}}{qw<user addr>} ),
        qq<perl -wE 'say -s q($file)'>
    );

    my ($stdout, $stderr) = capture {
        system @cmd;
    };

    return 0 + $stdout
      if $stdout ne "\n";

    die "unknown error: $stderr";
}
