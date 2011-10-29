#!/usr/bin/env perl
#
# Taps the first n lines (n given by -n as for head) and feeds it to the named
# command.  The rest of the lines are fed back to stdout.
#
# Usage example:
# cat lines.txt | tap -25 "cat >first25.txt" | tap -20 "cat >next20.txt" | ...
#
# anand venkataraman - Feb, 2003
#
use strict;
use warnings;

MAIN: {
  my $numLines = 10;  # Default
  my $command = "| cat";

  while (my $arg = shift(@ARGV)) {
    if ($arg =~ /-n/) {
      $numLines = shift(@ARGV);
    } elsif ($arg =~ /^-[0-9]+/) {
      $numLines = $arg;
      $numLines =~ s/^-//;
    }  elsif ($arg =~ /-c/) {
      $command = shift(@ARGV);
    } elsif ($arg =~ /^-h/) {
      usage();
    } else {
      $command = "$arg @ARGV";
    }
  }

  die "The number of lines must be a positive integer, not \"$numLines\"\n" if ($numLines !~ /^\d+$/);
  if (!open(C, $command) && !open(C, " | $command") && !open(C, "| cat >$command")) {
    die "Could neither open $command nor pipe into it or write to it!\n";
  }

  while (<STDIN>) {       # First n lines go to $command
    last if $numLines-- <= 0;
    print C;
  }

  do {                    # The rest of the lines go to stdout.
    print;
  } while (<STDIN>);

  close(C);      
  exit 0;
}

sub usage {
  print STDERR <<".";
    Tap: Taps the first n lines (n given by -n as for head) and feed it
         to the named command.  The rest of the lines are fed back to stdout.

    Usage example:
      cat lines.txt | tap -n 25 "cat >first25.txt" | tap -20 "cat >next20.txt" | ...

.
  exit(1);
}
