#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use File::Temp qw(tempdir);
use File::Temp::MoreUtils qw(tempfile_named);

my $tempdir = tempdir(CLEANUP => !$ENV{DEBUG});
subtest tempfile_named => sub {
    chdir $tempdir or die;

    my $fh;
    open $fh, ">", "a" or die;
    open $fh, ">", "b.txt" or die;
    open $fh, ">", "c." or die;
    mkdir "d1" or die;

    dies_ok { tempfile_named() } "no name arg -> dies";
    is_deeply([tempfile_named(name => "a")]->[1], "a.1");
    is_deeply([tempfile_named(name => "a")]->[1], "a.2");

    is_deeply([tempfile_named(name => "b.txt")]->[1], "b.1.txt");
    is_deeply([tempfile_named(name => "b.txt")]->[1], "b.2.txt");

    is_deeply([tempfile_named(name => "c.")]->[1], "c..1");
    is_deeply([tempfile_named(name => "c.")]->[1], "c..2");

    subtest "dir arg" => sub {
        is_deeply([tempfile_named(name => "a", dir=>"d1")]->[1], "d1/a");
        is_deeply([tempfile_named(name => "a", dir=>"d1")]->[1], "d1/a.1");

        like([tempfile_named(name => "a", dir=>undef)]->[1], qr{[/\\]a\z});
        like([tempfile_named(name => "a", dir=>undef)]->[1], qr{[/\\]a\.1\z});

        dies_ok { tempfile_named(name => "a", dir=>"$tempdir/noexist") } "dir doesn't exist -> dies";
    };

    subtest "suffix_start arg" => sub {
        is_deeply([tempfile_named(name => "a", suffix_start=>"tmp1")]->[1], "a.tmp1");
        is_deeply([tempfile_named(name => "a", suffix_start=>"tmp1")]->[1], "a.tmp2");
    };
};

done_testing;
