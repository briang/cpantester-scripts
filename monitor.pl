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
    fbsd   => 'test@fbsd',
    laptop => 'bri@lappy',
    zippy  => 'test@localhost',
);

for (@ARGV) {
    die "unknown argument ($_)\n" unless s/^-//;
    die "unknown machine ($_)\n" unless exists $smokers{$_};

    delete $smokers{$_};
}

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

        my $alert;
        $alert = "DB"
          if   $db_length == $db_prev
            && time - $data{$smoker}{db_time}  >= $DB_PERIOD;

        $alert = "log"
          if   $log_length == $log_prev
            && time - $data{$smoker}{log_time} >= $LOG_PERIOD;

        if ($alert) {
            alert("$smoker seems stalled ($alert)");
            next;
        }

        @{$data{$smoker}}{qw<db db_time>} = ( $db_length, time )
          if $db_length != $db_prev;

        @{$data{$smoker}}{qw<log log_time>} = ( $log_length, time )
          if $log_length != $log_prev;
    }
    sleep $SCAN_PERIOD;
}

sub alert {
    my $time = sprintf "%02d:%02d ", (localtime)[2,1];
    say $time, @_, "\a";
    sleep 1;
}

sub filesize {
    my $smoker = shift;
    my $file   = shift;

    my @cmd = (
        'ssh', $smokers{$smoker}, qq<perl -wE '-e q($file) and say -s _'>
    );

    my ($stdout, $stderr) = capture { system @cmd };

    alert("unknown error: $stderr")
      if $stderr; # XXX TODO cater for boxen being down

    #dd $smoker, $file, $stdout+0;

    $stdout ||= 0; # tester is up, but not smoking

    return 0 + $stdout;
}
