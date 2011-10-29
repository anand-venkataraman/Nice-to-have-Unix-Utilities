#!/usr/bin/env perl
# Strictly a filter, this histograms incoming data points into requested bin sizes.  If
# bin sizes are not given with the -interval option, then the interval is assumed to be
# max-min/10
# &: Jan 28, 2003
#
use strict;
use warnings;
use POSIX qw(floor ceil);

sub usage {
  print STDERR "Usage: $0 -min MIN -max MAX -int INTERVAL [-stars] [-scale] [-quiet]\n\n";
  print STDERR "Strictly a filter, this histograms incoming numerical data points into\n"
             . "requested bin sizes.\n\n"
             . "The program will print a same-line progress message as the input is\n"
             . "being read in, with out-of-range (< min or > max) values reported to\n"
             . "the left, between and the right of ] and [ resp. To suppress this,\n"
             . "use the -q option\n\n"
             . "Note that -min and -max clip the histogram, but don't affect the basic\n"
             . "statistcs - e.g. mean and variance\n\n";
  
  print STDERR "Use -stars to print a horizontal bar of stars for each bin\n";
  print STDERR "Use -scale to increase the weight of each star, if -stars is used\n\n";
  exit 1;
}

MAIN: {
  my $intervalWidth = undef;
  my $min = undef;
  my $max = undef;
  my $useStars = undef;        # Print horiz histogram with hash-marks
  my $scale = 1;               # If $useStars, each * represents a count of this much.
  my $quiet = 0;               # Should we suppress progress messages as data is read in?

  while (my $arg = shift(@ARGV)) {
    if ($arg =~ /^-h(elp)?$/) {
      usage();
    } elsif ($arg =~ /^-q/) {
      $quiet = 1;
    } elsif ($arg =~ /^-int/) {
      $intervalWidth = shift(@ARGV);
    } elsif ($arg =~ /^-min/) {
      $min = shift(@ARGV);
    } elsif ($arg =~ /^-max/) {
      $max = shift(@ARGV);
    } elsif ($arg =~ /^-star/) {
      $useStars = 1;
    } elsif ($arg =~ /^-scale/) {
      $scale = shift(@ARGV);
    } elsif ($arg =~ /^-/) {
      print STDERR "Unknown option: $arg\n";
      usage();
    } else {
      last;
    }
  }
  usage() if (!defined($max) || !defined($min) || !$intervalWidth || $intervalWidth < 0);

  # We have ($max-$min)/$intervalWidth bins.
  my ($sum, $sumSq, $num, $ltMin, $gtMax) = (0,0,0,0,0);
  my ($actualMin, $actualMax) = (undef, undef);
  my @bins = ();
  
  while (my $line = <STDIN>) {
    my @f = split(/\s+/, $line);
    foreach my $val (@f) {
      next if $val =~ /^\s*$/;

      $sum += $val;
      $sumSq += $val * $val;
      $num++;
      if ($val < $min) {
	++$ltMin;
      } elsif ($val >$max) {
	++$gtMax;
      } else {
	my $binNdx = floor(($val-$min)/$intervalWidth);
	++$bins[$binNdx];
      }
      $actualMin = $val if (!defined $actualMin || $val < $actualMin);
      $actualMax = $val if (!defined $actualMax || $val > $actualMax);

      print STDERR "$ltMin ] $num [ $gtMax\r" if (!$quiet && $num%10000 == 0);
      print STDERR "$ltMin ] $num [ $gtMax\n" if (!$quiet && $num%1000000 == 0);
    }
  }

  # Misc Stats
  my $mean = $num == 0? 0 : $sum/$num;
  my $var = $num == 0? 0 : $sumSq/$num - $mean * $mean;
  my $sd = sqrt($var);

  $scale = 1 if ($scale <= 0);
  print "# NumSamples = $num; Max = $actualMax; Min = $actualMin\n";
  print "# Mean = $mean; Variance = $var; SD = $sd\n";
  print "# Each * represents a count of $scale\n" if ($useStars);

  # Use a flag to indicate whether we are within a range of consecutive
  # empty bins to better format output. Assume gaps to the left of
  # min bin to start.
  my $inGap = 1;

  my $haveStarted = 0;
  my $numBins = ($max-$min)/$intervalWidth;
  for (my $i = 0; $i < $numBins; $i++) {
    $bins[$i] = 0 if !defined($bins[$i]);
    next if (!$haveStarted && $bins[$i] == 0);
    $haveStarted = 1;

    my $lo = $min + $i*$intervalWidth;
    my $hi = $min + ($i+1)*$intervalWidth;

    # Print a blank line in lieu of multiple consecutive empty bins
    next if ($inGap && $bins[$i] == 0);
    if ($bins[$i] == 0) {
      print "\n";
      $inGap = 1;
      next;
    }
    $inGap = 0;

    my $tag = sprintf("%.4f - %.4f", $lo, $hi);
    if ($useStars && $scale != 0) {
      printf "%20s [%6d]: %s\n", "$tag", $bins[$i], getStringOfLength($bins[$i]/$scale);
    } else {
      printf "%20s: %d\n", "$tag", $bins[$i];
    }
  }
}

#----------------------------------------------------------------------

sub getStringOfLength {
  my($n) = @_;
  my $s = "";
  
  for (my $j = 0; $j < $n; $j++) {
    $s .= "*";
  }
  return $s;
}  



