#!/usr/local/bin/perl

use 5.010;

use strict;
use warnings FATAL => 'all';
#use diagnostics;

use Data::Dump;
#use Carp qw();

$|=1;
################################################################################
use File::Find::Rule::Perl;
use Module::CoreList;

use constant {
   #BASE_DIR => '.',
   #BASE_DIR => $ENV{HOME},
    BASE_DIR => "$ENV{HOME}/git/",
};

@ARGV = File::Find::Rule->perl_file->in(BASE_DIR);

my %seen;
my $count;
while (<ARGV>) {
    next unless -f $ARGV;
    next if     -l $ARGV;
    next if        $ARGV =~ /\.git/;
    if (my ($p) = /\b(?:use|require)\s+([\w:]+)/) {
        s/#.*//;
        next unless $p =~ /[a-z]/i; # use 5.010;
        next if is_core($p);
        $seen{$p}++;
        print "\r", ++$count;
    }
}

say for sort { lc $a cmp  lc $b } keys %seen;

sub is_core { $Module::CoreList::version{$]}{+shift} }

__DATA__
use CPAN::DistnameInfo
use CPAN::Meta
use Capture::Tiny
use DBD::SQLite
use DBI
use Data::Dump
use Devel::PatchPerl
use Emacs::PDE
use File::Find::Rule
use File::Find::Rule::Perl
use Getopt::Lucid
use LWP
use LWP::Simple
use Method::Signatures::Simple
use Mo
use MooseX::Declare
use Parse::CPAN::Packages::Fast
use Path::Class::Rule
use SQL::Abstract::More
use Template
use Test::Most
use Text::Table
use Try::Tiny
