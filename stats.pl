#!/usr/bin/env perl
#
# Print mean, var, etc. of input values
#
# anand venkataraman - Jun 1999
#
use strict;
use warnings;

MAIN: {
  my ($n, $sum, $sumsq, $mean, $var, $sd, $min, $max);
  $n = $sum = $sumsq = $mean = $var = $sd = 0;

  # No command line args needed. If given, assume help.
  usage() if (my $arg = shift(@ARGV));

  # Although we say we expect input in one value per line
  # we tolerate multiple space-separated values on each line
  #
  while (my $line = <STDIN>) {
    my @vals = split(/\s+/, $line);
    foreach my $val (@vals) {
      $min = $max = $val if ($n == 0);
      $min = $val if ($min > $val);
      $max = $val if ($max < $val);
      $sum += $val;
      $sumsq += $val * $val;
      ++$n;
    }
  }
  $mean = $sum/$n;
  $var = $sumsq/$n - $mean*$mean;
  $sd = sqrt($var);

  print "N = $n\n"
    . "Sum = $sum\n"
    . "SumSq = $sumsq\n"
    . "Mean = $mean\n"
    . "Min = $min\n"
    . "Max = $max\n"
    . "Var = $var\n"
    . "SD = $sd\n";
}

sub usage {
  print STDERR "Usage: cat numbers.txt | stats.pl\n";
  print STDERR "stats.pl prints basic statistics over input numbers.\n";
  print STDERR "Input should be a series of numbers, ideally one per line.\n";
  exit(1);
}
