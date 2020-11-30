#!/usr/bin/perl
#require 5.008;
{ package main;
  my $TS = 'Time-stamp: <2020-11-30T18:41:02Z>';
  $TS =~ s/Time-stamp\:\s+<(.*)>/$1/;
  my $AUTHOR = "JRF (http://jrf.cocolog-nifty.com/)";
  our $VERSION = "0.0.1; make_emoji_skk_dic.pl; last modified at $TS; by $AUTHOR";
  our $DEBUG = 1;
}

use strict;
use warnings;
use utf8; # Japanese English

use Encode;
#use Encode::JIS2K;
use Unicode::Japanese;
use IO::Handle;
use Getopt::Long qw();

our $ENCODING = "utf8";
our $JISX0213 = 0;
our $OUTPUT = "emoji-skk-dic.txt";
our $EMOJI_VERSION = "2.2.1";

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

Getopt::Long::Configure("bundling", "auto_version", "no_ignore_case");
Getopt::Long::GetOptions
  (
   "o=s" => \$OUTPUT,
   "v=s" => \$EMOJI_VERSION,
#   "s" => sub { $ENCODING = "cp932";},
#   "e" => sub { $ENCODING = "euc-jp"; },
   "u" => sub { $ENCODING = "utf8"; },
#   "jisx0213" => sub { $JISX0213 = 1; },
   "man" => sub {pod2usage(-verbose => 2)},
   "h|?" => sub {pod2usage(-verbose => 0, -output=>\*STDOUT, 
				-exitval => 1)},
   "help" => sub {pod2usage(1)},
  ) or usage(1);

if (@ARGV != 1) {
  usage(1);
}

sub usage {
  print "Usage: perl make_emoji_skk_dic.pl emoji.txt\n";
  print "\nYou can get emoji.txt of v2.2.1 from https://github.com/peaceiris/emoji-ime-dictionary/releases .\n";
  exit(@_);
}

sub uniq {
  my (@s) = @_;
  my @r;
  my %ex;
  foreach my $x (@s) {
    push(@r, $x) if ! exists $ex{$x};
    $ex{$x} = 1;
  }
  return @r;
}

MAIN:
{
  my $DIC = $ARGV[0];

  open(my $ih, "<", $DIC) or die "$DIC: $!";
  binmode($ih);

  if ($JISX0213 && $ENCODING eq "euc-jp") {
    $ENCODING = "euc-jisx0213";
    require Encode::JIS2K;
  }

  my $enc = Encode::find_encoding($ENCODING);

  my %orig;

  while (my $s = <$ih>) {
    $s = $enc->decode($s);
    $s =~ s/\s+$//s;
    next if $s =~ /^\s*#/;
    next if $s =~ /^\s*$/;
    my ($yomi, $emoji, $kigou, @rest) = split(/\s+/, $s);
    die "Parse Error"
      if @rest || $kigou ne "記号" || substr($yomi, 0, 1) ne ":";
    $yomi = substr($yomi, 1);
    if (! exists $orig{$yomi}) {
      $orig{$yomi} = [];
    }
    my $ex = 0;
    foreach my $x (@{$orig{$yomi}}) {
      if ($x eq $emoji) {
	$ex = 1;
	# print "ex $yomi $emoji\n";
	last;
      }
    }
    push(@{$orig{$yomi}}, $emoji) if ! $ex;
  }
  close($ih);

  my %dic1;
  my %eng = (
	     "かた" => "type",
	     "やじるし" => "arrow",
	     "まーく" => "mark",
	     "めーる" => "mail",
	     "のて" => "hand",
	     "のぽーずをするおとこ", => "posemale",
	     "のぽーずをするおんな", => "posefemale",
	     "のぽーずをするにん" => "pose",
	     "しゃつ" => "shirt",
	     "くるま" => "car",
	     "さいん" => "sign",
	     "じけいじしゃく" => "magnet",
	    );

  foreach my $yomi (sort {$a cmp $b} (keys %orig)) {
    my @emoji = @{$orig{$yomi}};
    if ($yomi eq "もりのにん") {
      $yomi = "もりのひと";
      my $y = "もりのにん";
      $dic1{$y} = [] if ! exists $dic1{$y};
      push(@{$dic1{$y}}, $emoji[0]);
    }

    if ($yomi =~ /^[A-Z01-9\+\-]+/) {
      my $y1 = $&;
      my $y2 = $';
      if ($y2 ne "") {
	die "Parse Error: $yomi" if ! exists $eng{$y2};
	$y2 = $eng{$y2};
      }
      $yomi = $y1 . $y2;
    } else {
      if ($yomi =~ /にん$/) {
	my $y;
	my $y1 = $`;
	if ($y1 =~ /なかの$/) {
	  $y = $`;
	} elsif ($y1 =~ /の$/) {
	  $y = $`;
	} elsif ($y1 =~ /をする$/) {
	  $y = $`;
	} elsif ($y1 =~ /する$/) {
	  $y = $`;
	} elsif ($y1 =~ /な$/) {
	  $y = $`;
	} elsif (! grep {$y1 eq $_} ("", "はん", "ばるかん")) {
	  $y = $y1;
	  # warn "Parse Warn: $y";
	}
	if (defined $y) {
	  if (@emoji != 1) {
	    warn("Parse Warn: $yomi");
	  }
	  if (! (exists $orig{$y} && grep {$emoji[0] eq $_} @{$orig{$y}})) {
	    print "add $y $emoji[0]\n";
	    $dic1{$y} = [] if ! exists $dic1{$y};
	    $dic1{$y} = [uniq(@{$dic1{$y}}, $emoji[0])];
	  }
	}
      }
    }
    $dic1{$yomi} = [] if ! exists $dic1{$yomi};
    $dic1{$yomi} = [uniq(@{$dic1{$yomi}}, @emoji)];
  }

  my %revdic;
  foreach my $yomi (sort {$a cmp $b} (keys %dic1)) {
    my @emoji = @{$dic1{$yomi}};
    foreach my $emoji (@emoji) {
      if (length($emoji) == 1) {
	if (! exists $revdic{$emoji}
	    || length($revdic{$emoji}) > length($yomi)) {
	  $revdic{$emoji} = $yomi;
	}
      }
    }
  }
  open(my $oh, ">", $OUTPUT) or die "$OUTPUT: $!";
  binmode($oh, ":utf8");
  print $oh <<"EOT";
;; -*- mode: fundamental; coding: utf-8 -*-
;;
;; MIT License
;;
;; Copyright 2018 yag_ays (for the emoji dictionaries: emoji.tsv emoji.txt emoji.*.txt)
;; Copyright (c) 2020 Shohei Ueda (\@peaceiris) (for emoji.txt)
;; Copyright (c) 2020 JRF (for emoji-skk-dic.txt* make_emoji_skk_dic.pl)
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;; 
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONN
;;
;; Author's Link:
;;
;;   http://jrf.cocolog-nifty.com/software/
;;   (The page is written in Japanese.)
;;
;; Notice:
;;
;;   This file was made from emoji.txt v${EMOJI_VERSION} which was gotten from
;;
;;   https://github.com/peaceiris/emoji-ime-dictionary
;;
EOT

  my @s;
  foreach my $emoji (sort {$revdic{$a} cmp $revdic{$b}} (keys %revdic)) {
    push(@s, "$emoji$revdic{$emoji}")
  }
  print $oh ("@@ " . join("/", @s) . "\n");
  foreach my $yomi (sort {$a cmp $b} (keys %dic1)) {
    my @emoji = @{$dic1{$yomi}};
    if ($yomi =~ /^[A-Z01-9\+\-]/) {
      $yomi = "@@" . $yomi;
    } else {
      $yomi = "＠＠" . $yomi;
    }
    print $oh ($yomi . " " . join("/", @emoji) . "\n");
  }
  close($oh);
}
