#!usr/bin/perl
# This program is to create histograms of flux density (or any value)
# it will take in the proper files and convert them into histograms
use PDL;
use PGPLOT;

require "openDBI.pl";

$alpha = -0.7;

#--------------------------------------------
# Set up parameters for MySQL access

my $dbh;
$dbh = openDBI();

#--------------------------------------------
# Get  z,extended and core flux of the source from the 
# database

@z = @{$dbh->selectcol_arrayref("SELECT z FROM sources WHERE MOJAVE_1='Y' order by source")};
@S_ext = @{$dbh->selectcol_arrayref("SELECT extflux FROM VLAdata order by source")};
@S_core = @{$dbh->selectcol_arrayref("SELECT coreflux FROM VLAdata order by source")};

$dev = '/ps';


for ($i=0;$i<135;$i++) {
    
    if($z[$i]==0){
	$z[$i] = 1;
    }

    $R_c[$i] = &log10($S_core[$i])-&log10($S_ext[$i])+$alpha*&log10(1+$z[$i]);
    
    $i++;
}#for


pgbegin(0,$dev,1,1);  # Open plot device
pgsch(2);
histo(-1,0,0.2,-1,'R_c MOJAVE', $title, @R_c);

#---------------------------------------------------------------------------
#The routine below marks bins in the histogram with symbols.  In this case
#To mark sources whose extended emissions are an upper limit. This makes the
#log(Sc/Se) a lower limit. Coordinates for the plot are the same as the axis
#So for two sources in the 3.0-3.2 bin coordinates (0.5,3.1)and (1.5,3.1)
#are recommended center the symbols in the bin. The 29 in pgpnts is an arrow
#pointing right, 28 points left.
#---------------------------------------------------------------------------

#$nlimit = 4; #number-1 of sources whose ext flux are constrained by a limit
#@xlimit = (3.1,3.1,2.9,2.7,2.7);#y coordinate middle of the bin for each limit
#@ylimit = (0.5,1.5,0.5,0.5,1.5);#x """""""""""""""""""""""""""""""""""""""""""
#foreach (0..$nlimit){
 #  pgsch(0.75);
  # pgpnts(1,@xlimit[$_],@ylimit[$_],29,0);
#}

sub log10 {
	my $n = shift;
	return log($n)/log(10);
    }


#--------------------------------------------------------------------------
# Subroutines for determining maximum and minimum array values
#----------------------------------------------------------------------------
sub max {
    my $max = shift(@_);
    my $num = @_;
    for my $num (@_) {
	$max = $num if $max < $num;
    }
    return $max;
}

sub min {
    my $min = shift(@_);
    my $num = @_;
    for my $num (@_) {
	$min = $num if $min > $num;
    }
    return $min;
}



#----------------------------------------------------------------------------
# Histograms
#
# inputs: $binmin, $binmax, $binwidth, $ymax, $xlabel, $title, $data_array
# output: graph
# nb. set binmax < binmin if you want a self-scaled x-axis

#---------------------------------------------------------------------------
sub histo {
  my $binmin = shift(@_);
  my $binmax = shift(@_);
  my $binwidth = shift(@_);
  my $ymax = shift(@_);
  my $xlabel = shift(@_);
  my $title = shift(@_);
  my @ar = (0);
  my @ar = @_;
  my @hist = (0);
  my @x=(0);
  my @xx=(0);

  $dev = "?" unless defined $dev;  # "?" will prompt for device
  printf "Use (l)eftpoint or (m)idpoint x-axis bin labels? [default=l]: ";
  $binlabel = <STDIN>; chomp ($binlabel); 

  for (my $i = 0; $i < $#ar; $i++) {
#    printf "%s \n", $ar[$i];
    $bin_num = ($ar[$i]-$binmin)/$binwidth;
    $bin_num = sprintf("%d",$bin_num);
    if ($bin_num >= 0) { $hist[$bin_num] += 1;}
  }

  $nbin = ($binmax-$binmin)/$binwidth;
  $nbin = 1+sprintf("%d",$nbin);
  if ($binmax < $binmin) {$nbin = $#hist+1;}  # for self-scaled x axis
  $hist[$nbin]= 0;

  for $i (0..$nbin) {
    if ($binlabel eq 'm' or $binlabel eq 'M') {
      $x[$i] = $binmin+$i*$binwidth+$binwidth/2; 
      $xx[$i] = $binmin+$i*$binwidth;  
    }
    else { 
      $x[$i] = $binmin+$i*$binwidth;  
      $xx[$i] = $binmin+$i*$binwidth+$binwidth/2; 
    }
    if ($hist[$i] < 1) {$hist[$i]=0;}
  }

  # Set plot environment and labels

  if ($ymax < 0) {   # for self-scaled y axis
    $ymax = max(@hist);
    $ctemp = $ymax/7;
    $y_upper = $ymax + sprintf("%d",$ctemp);
    pgenv($binmin, $xx[$nbin], 0, $y_upper,0,0);
  }
  else {
    pgenv($binmin, $xx[$nbin], 0, $ymax,0,0);
  }
  pgbox('BCNST', 5, 10, 'CNST', 0,0);
  pglabel($xlabel,"Number per bin",$title);
  pgbin($nbin, \@xx, \@hist, 1);

  print "\n Write out histogram values to disk file? (y/n) : ";
  $resp = <STDIN>; chomp ($resp); 
  if ($resp eq 'y') { 
    $k = 1;
    $outfile = 'hist'.$k.'.out';
    while (open(HISTOUT, "$outfile")) {$k++; $outfile = 'hist'.$k.'.out'; }
    open(HISTOUT, ">$outfile");
    for $i (0..$nbin) {printf HISTOUT "%s %s \n", $x[$i],$hist[$i];}
    printf "Histogram values written to %s \n", $outfile;
    close HISTOUT;
  }
}
