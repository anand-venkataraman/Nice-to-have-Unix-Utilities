#!/usr/bin/perl
#
# Mostly the same as tee(1) but the named file is interpreted as a
# command to pipe into.
#
# Usage example:
#   cat lines.txt | teeproc "randomize >randomlines.txt"
#
# E.g. Try:
#   seq 10 | ./teeproc.pl -c "wc >/dev/tty" | ./teeproc.pl -c "wc  >/dev/tty" | wc
#
# anand venkataraman - Feb 2003
#
use strict;
use warnings;

MAIN: {
  my $command = "| cat";  # Default

  while (my $arg = shift(@ARGV)) {
    if ($arg =~ /-c/) {
      $command = shift(@ARGV);
    } else {
      $command = "$arg @ARGV";
    }
  }

  if (!open(C, $command) && !open(C, " | $command") && !open(C, " >$command")) {
    die "Could neither open $command nor pipe into it or write to it!\n";
  }

  # Print each input line both into the named command as well as on stdout
  #
  while (my $line = <STDIN>) { 
    print $line;
    print C $line;
  }
  close(C);      

  exit 0;
}
