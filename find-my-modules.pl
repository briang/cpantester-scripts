#!/usr/local/bin/perl

use 5.010;

use strict;
use warnings FATAL => 'all';
#use diagnostics;

use Data::Dump;
#use Carp qw();

$|=1;
################################################################################
use autodie;
use File::Find;
use Module::CoreList;
use Parse::CPAN::Packages::Fast;
use Try::Tiny;

use constant {
   #BASE_DIR => '.',
   #BASE_DIR => "$ENV{HOME}/git/",
    BASE_DIR => $ENV{HOME},
    IGNORE   => join( "|", map { "(?:$_)" } qw(
        /\.git/
        /home/bri/src/
        /home/bri/\.cpan(?:m|plus)?
        (?:\.bak|~)$
    )),
    PACKAGES   => "/mirrors/cpan/modules/02packages.details.txt.gz",
    STOP_WORDS => {
        map { $_ => 1 } qw(

            any as example Foo_Bar_Accessor Foo_Bar_Accessor2
            Foo_Bar_Tiny Foo_Bar_Tiny2 the with your

        )
    },
};

my @Files;
find(\&finder, BASE_DIR);
@ARGV = @Files;

my $packages = Parse::CPAN::Packages::Fast->new(PACKAGES);

my %seen;
my $count;
while (<ARGV>) {
    s/#.*//;
    if (my ($p) = /\b(?:use|require)\s+([\w:]+)/) {
        next unless $p =~ /[a-z]/i; # use 5.010;
        next if STOP_WORDS->{$p};
        next if is_core($p);
        my $mod = try {
            $packages->package($p);
        } catch {
            die $_ unless /^Package .*? does not exist/;
            undef;
        };
        next unless $mod;

        $seen{$p}++;
#        print "\r", ++$count;
#say "$ARGV => $p" if $p =~ /fast/i;
    }
}

say for sort { lc $a cmp  lc $b } keys %seen;

sub is_core { $Module::CoreList::version{$]}{+shift} }

sub finder {
    return if $File::Find::name =~ eval "qr<" . IGNORE . ">";

    return unless -f $File::Find::name;
    return if     -l $File::Find::name;
    return if     -B $File::Find::name;

    return unless is_perl_file($File::Find::name);

    push @Files, $File::Find::name;
}

sub is_perl_file {
    local $_ = shift;
    return 1 if /\.(?:t|pm|pl)$/;

    open my $IN, "<", $_;
    return <$IN> =~ /^#!.*perl/;
}

__DATA__
use App::perlbrew;
use App::cpanminus;
use App::cpanoutdated;
use CPAN::DistnameInfo;
use CPAN::Meta;
use Capture::Tiny;
use DBD::SQLite;
use DBI;
use Dancer;
use Data::Dump;
use Devel::PatchPerl;
use File::Find::Rule;
use File::Find::Rule::Perl;
use Getopt::Lucid;
use LWP;
use LWP::Simple;
use Method::Signatures::Simple;
use Mo;
use MooseX::Declare;
use Parse::CPAN::Packages::Fast;
use Path::Class::Rule;
use SQL::Abstract::More;
use Template;
use Test::Most;
use Text::Table;
use Try::Tiny;
