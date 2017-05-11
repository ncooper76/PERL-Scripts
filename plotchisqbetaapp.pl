#!/usr/bin/perl

#####################################################################
# Program to perform chisquare and histogram analysis of Monte Carlo
#  sim output vis a vis MOJAVE maximum speed data 
#
# usage: fluxsamp-plot.pl <input_filename>
#####################################################################

use PGPLOT;
use PDL;
use PDL::Math;
use PDL::Image2D;
use PDL::Graphics::PGPLOT;
use DBI;
require "openDBI.pl";
print "Enter output file to plot (default: fluxsamp.out): ";
$dat=<STDIN>;
chop $dat;
$PI = 4*atan2(1,1);
if (!@ARGV[0]) {printf "No data filename given, so using fluxsamp.out \n";
$dat='fluxsamp.out';} 
else { $dat = @ARGV[0]; }


#Set random number seed randomly 
 srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip`);  

$par = 'fluxsamp.par';

open(DAT, "$dat")  ||  die "cannot open $dat $!\n";
open(PAR, "$par")  ||  die "cannot open $par $!\n";

$dbh = openDBI();  # Open DBI interface to SQL
$n_mojave = -1;
$nfit = -1;
    
# Retrieve modelfit data on the source from the database
my $sth = $dbh->prepare ("select source,lumdist,z,max2cmvlbaflux,maxMu, decsign,maxdMu,maxMu_ref,opt_class,2cmVLBAmax, 2cmVLBAmin,2cmVLBAmedian from sources where MOJAVE_1='Y' and z > 0 and maxMu is not NULL and opt_class not like 'G%' and spect_class not like 'GPS%' and source not like '0805-%';");
$sth->execute();

while (my ($source,$lumdist, $z, $maxMOJAVEflux,$maxMu,$decsign,$maxdMu,$maxMu_ref,$oclass, $maxflux, $minflux,$medianflux) = $sth->fetchrow_array ())
  { $n_mojave++;
    $angspeed_M[$n_mojave] = $maxMu;
    $dangspeed_M[$n_mojave] = $maxdMu;
    $lumdist_M[$n_mojave] = $lumdist;
    $Mu_ref[$n_mojave]= $maxMu_ref;
    $srcname[$n_mojave]= $source;
    $s_M[$n_mojave]=  $max2cmvlbaflux;
    $optclass[$n_mojave] = $oclass;
    if ($lumdist_M[$n_mojave] > 0) {
      $beta_M[$n_mojave]= $maxMu*$lumdist/63.24217/(1+$z);
      $dbeta_M[$n_mojave]= $maxdMu*$lumdist/63.24217/(1+$z);
      $z_M[$n_mojave]=     $z;
      $lumdist_M[$n_mojave]= $lumdist;
      if ($maxMOJAVEflux <= 0) {printf "Error: no maximum 2cm VLBA flux for $source \n"; next;}
      if ($lumdist <=0) {printf "Error: no luminosity distance for  $source \n"; next;}
      if ($z <=0) {printf "Error: no redshift for  $source \n"; next;}
      $logL_M[$n_mojave]=  20.07786+log10($lumdist*$lumdist/(1+$z)*$medianflux);
      $maxlogL_M[$n_mojave]=  20.07786+log10($lumdist*$lumdist/(1+$z)*$maxflux);
    }
  }

printf "Finished reading in data for %d MOJAVE sources \n",$n_mojave+1;

for ($n = 1; $n <= $n_mojave; $n++) {
## Get the mean core flux
  my $sth = $dbh->prepare ("select meanflux from components join sources where sources.source='$srcname[$n]' and sources.source=components.source and observer=usewhichfit  and id = 0 group by id;");
  $sth->execute();
  $meancoreflux[$n] = $sth->fetchrow_array ();

## Get the maximum core flux \n";
  my $sth = $dbh->prepare ("select max(flux) from components join sources where sources.source='$srcname[$n]' and sources.source=components.source and epoch < '2008-01-01' and freq like '1%' and observer=usewhichfit  and id = 0;");
  $sth->execute();
  $maxcoreflux[$n] = $sth->fetchrow_array ();

  ## Get the minimum  core flux
  my $sth = $dbh->prepare ("select min(flux) from components join sources where sources.source='$srcname[$n]' and sources.source=components.source and epoch < '2008-01-01' and freq like '1%' and observer=usewhichfit  and id = 0;");
  $sth->execute();
  $mincoreflux[$n] = $sth->fetchrow_array ();

## Get the maximum total flux \n";
  my $sth = $dbh->prepare ("select max(2cmvlbatot) from epochs where source='$srcname[$n]' and epoch < '2008-01-01' and frequency like '1%';");
  $sth->execute();
  $maxflux[$n] = $sth->fetchrow_array ();

## Get the minimum total flux \n";
  my $sth = $dbh->prepare ("select min(2cmvlbatot) from epochs where source='$srcname[$n]' and epoch < '2008-01-01' and frequency like '1%';");
  $sth->execute();
  $minflux[$n] = $sth->fetchrow_array ();


  if ($lumdist_M[$n] > 0) {
    $maxlogL_M[$n] = 20.07786+log10($lumdist_M[$n]*$lumdist_M[$n]/(1+$z_M[$n])*$maxflux[$n]);
    $minlogL_M[$n] = 20.07786+log10($lumdist_M[$n]*$lumdist_M[$n]/(1+$z_M[$n])*$minflux[$n]);
    $maxlogLcore_M[$n]=  20.07786+log10($lumdist_M[$n]*$lumdist_M[$n]/(1+$z_M[$n])*$maxcoreflux[$n]);
    $minlogLcore_M[$n]=  20.07786+log10($lumdist_M[$n]*$lumdist_M[$n]/(1+$z_M[$n])*$mincoreflux[$n]);
    $logLcore_M[$n]=  20.07786+log10($lumdist_M[$n]*$lumdist_M[$n]/(1+$z_M[$n])*$meancoreflux[$n]);
  }
}



printf "Now reading in values from $dat ... \n";
# Index fluxsamp.out data into array.

$k = 0;
while (<DAT>){
  ($logs[$k],$z[$k],$logL[$k],$beta[$k],$gamma[$k],$theta[$k],$delta[$k])=split;
  if ($gamma[$k] !~ /\d/) {next;}
  if ($delta[$k] !~ /\d/) {next;}
  if ($theta[$k] !~ /\d/) {next;}

# Randomly sample the monte carlo data to mimic missing data points
  if (rand() > 0.88) {next;}

  $thetacrit[$k] = asin(1/$gamma[$k])*180/$PI;
  $gammatheta[$k]= $gamma[$k]*sin($theta[$k]*$PI/180);
  $betatheta[$k] = $beta[$k]*sin($theta[$k]*$PI/180);
  if ($theta[$k] > 0) {
  $nthetacrit[$k] =  log10($theta[$k]/$thetacrit[$k]);}
  if ($delta[$k] > 0) {
  $tb[$k] = log10(5e10*$delta[$k]);}
  $k++;
}
close(DAT);
$ndat = $k;

printf "Comparing %d MOJAVE data points to %s Monte Carlo data points\n",$n_mojave+1,$ndat;

$binmin   = 0;
$binmax   = 60;
$binwidth = 5;

$nbin = ($binmax-$binmin)/$binwidth;
$nbin = 1+sprintf("%d",$nbin);

for (my $i = 0; $i <= $nbin; $i++) {
  $hist[$i] = 0;
  $hist_M[$i] = 0;
}

# Bin the MOJAVE data
for (my $i = 0; $i < $#beta_M; $i++) {
  $bin_num = ($beta_M[$i]-$binmin)/$binwidth;
  $bin_num = sprintf("%d",$bin_num);
  if ($bin_num >= 0) { $hist_M[$bin_num] += 1;}
}

#Bin the Monte Carlo data
for (my $i = 0; $i < $#beta; $i++) {
  $bin_num = ($beta[$i]-$binmin)/$binwidth;
  $bin_num = sprintf("%d",$bin_num);
  if ($bin_num >= 0) { $hist[$bin_num] += 1;}
}

for (my $i = 0; $i <  $#hist_M+1; $i++) {
  $chisq += ($hist_M[$i]-$hist[$i])**2;
}

printf "Chi-squared value is %.1f \n", $chisq;

# Plot apparent speed histogram

    
$dev = "?" unless defined $dev;  # "?" will prompt for device
$n_tot = $n_mojave+1;
$title = 'MOJAVE Sample: '.$n_tot.' (u,v) Modelfit Speeds';
pgbegin(0,$dev,1,1);  # Open plot device
pgsch(1.5); pgslw(2);

#      $dev = "?" unless defined $dev;  # "?" will prompt for device
#      printf "Use (l)eftpoint or (m)idpoint x-axis bin labels? [default=l]: ";
#      $binlabel = <STDIN>; chomp ($binlabel); 

pgenv(0,$binmax,0,50,0,0);
pgslw(3);

$nbin = ($binmax-$binmin)/$binwidth;
$nbin = 1+sprintf("%d",$nbin);

for $i (0..$nbin) {
  $x[$i] = $binmin+$i*$binwidth;  
  $xx[$i] = $binmin+$i*$binwidth+$binwidth/2; 
}


# Set plot environment and labels
pglabel("Maximum Measured Speed","N per bin",$title);
pgsls(4);
pgbin($nbin, \@xx, \@hist, 1);
pgsls(1);
pgsci(4);
pgbin($nbin, \@xx, \@hist_M, 1);



############################################################
#pgend;

$dev = "?" unless defined $dev;  # "?" will prompt for device
pgbegin(0,$dev,1,1);  # Open plot device
pgsci(1);

# Set lower and upper x and y axis limits
my $logL_min = min(@logL);
my $logL_max = max(@logL);

my $beta_min = 0;
my $beta_max = 53;
# Set plot environment and labels
$dev = "?" unless defined $dev;  # "?" will prompt for device
pgenv(22,30.5, $beta_min-1, $beta_max, 0, 0);
#   pgenv($logL_min-1.5, 29, $beta_min-1, 55, 0, 0);

pgsch(1.2);

    $n_tot = $n_mojave+1;
    pglabel("maximum log 15 GHz VLBA Luminosity [W/Hz]","Maximum Apparent Jet Speed [c]","");
#    pglabel("log 15 GHz VLBA Luminosity [W/Hz]","Maximum Apparent Jet Speed [c]","MOJAVE Sample: $n_tot AGN Jets");

    pgsch(1.4);
# Draw Legend
    pgsci(2);pgpt(1,23,32.5,4); pgtext(23.2,32,'Quasar');
    pgsci(10);pgpt(1,23,30.5, 10); pgtext(23.2,30,'BL Lac');
    pgsci(12);pgpt(1,23,28.5, 7); pgtext(23.2,28,'Radio Galaxy');
    pgsci(6);pgpt(1,23,26.5, 7); pgtext(23.2,26,'Simulated Source');
    
    $i = 1e-3;
# Parameters for envelope curve
    $gamma = 42;
    $Lint = 7e24;

    $beta = sqrt(1-1/$gamma/$gamma);
    $beta_a = $beta*sin($i*$PI/180)/(1-$beta*cos($i*$PI/180));
    $delta = $beta_a/$gamma/$beta/sin($i*$PI/180);
    $Lobs = $delta**2*$Lint;
    pgmove(log10($Lobs),$beta_a);
    
    for ($i = 1e-3; $i < 80; $i+=0.02) {
      $beta = sqrt(1-1/$gamma/$gamma);
      $beta_a = $beta*sin($i*$PI/180)/(1-$beta*cos($i*$PI/180));
      $delta = $beta_a/$gamma/$beta/sin($i*$PI/180);
      $Lobs = $delta**2*$Lint;
      pgdraw(log10($Lobs),$beta_a);
      pgsci(2);
    }
    pgsci(1);


# Plot MOJAVE data

    for my $line (0..$n_mojave) {
      pgsch(1);
      $pgsci = 1;
      if ($optclass[$line] =~ /Q/) {pgsci(2);$symbol = 4;}
      if ($optclass[$line] =~ /B/) {pgsci(10);$symbol = 10;}
      if ($optclass[$line] =~ /G/) {pgsci(12);$symbol = 7;}

      pgpt(1,$maxlogL_M[$line], $beta_M[$line], $symbol);
#      if ($Mu_ref[$line] =~ /SGJ/) {pgsci(6);} else {pgsci(7);}
#      pgerrx(1, $minlogL_M[$line], $maxlogL_M[$line], $beta_M[$line],0);
      pgerry(1,$maxlogL_M[$line] , $beta_M[$line]-$dbeta_M[$line], $beta_M[$line]+$dbeta_M[$line], 0);
#      printf "%s %s %8.2f %8.2f \n", $srcname[$line], $optclass[$line], $beta_M[$line], $logL_M[$line];
      # Plot line for source with unknown z:
#      $beta_z = 0.5*$lumdist_M[$line]/63.24217/(1+$z_M[$line]);
#      $logL_z=  20.07786+log10($lumdist_M[$line]*$lumdist_M[$line]/(1+$z_M[$line])*0.3);
#      pgsci(3);
#      pgpt(1,$logL_z, $beta_z,16);
    }
    pgsci(2);
    
# Plot sim data
      pgsci(6);
pgsch(5);
    for my $line (0..$ndat-1) {
        pgpt(1,$logL[$line], $beta[$line], 1);
    }







########################################################################
#-------------------------Subroutines----------------------------------#
########################################################################

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


#pghist($#z, \@z, 0,4,20,1);  
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
  pgslw(3);
  $dev = "?" unless defined $dev;  # "?" will prompt for device
  printf "Use (l)eftpoint or (m)idpoint x-axis bin labels? [default=l]: ";
  $binlabel = <STDIN>; chomp ($binlabel); 

  for (my $i = 0; $i < $#ar; $i++) {
    printf "%s \n", $ar[$i];
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
  pglabel($xlabel,"N per bin",$title);
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

#----2 histograms on same plot -------------
sub twohisto {
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


  for (my $i = 0; $i < $#ar; $i++) {
    $bin_num = ($ar[$i]-$binmin)/$binwidth;
    $bin_num = sprintf("%d",$bin_num);
    if ($bin_num >= 0) { $hist[$bin_num] += 1;}
  }

   pgslw(3);
#  $dev = "?" unless defined $dev;  # "?" will prompt for device
#  printf "Use (l)eftpoint or (m)idpoint x-axis bin labels? [default=l]: ";
#  $binlabel = <STDIN>; chomp ($binlabel); 
  $binlabel = 'l';

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


  pglabel($xlabel,"N per bin",$title);
  pgbin($nbin, \@xx, \@hist, 1);

#  print "\n Write out histogram values to disk file? (y/n) : ";
#  $resp = <STDIN>; chomp ($resp); 
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


#----------------------------------------------------------------------------
# Cumulative histograms
#---------------------------------------------------------------------------
  sub cumhisto {
  my $binmin = shift(@_);
  my $binmax = shift(@_);
  my $binwidth = shift(@_);
  my $ymax = shift(@_);
  my $xlabel = shift(@_);
  my $title = shift(@_);
  my @ar = @_;
  my @hist = ();
  printf "Use (l)eftpoint or (m)idpoint x-axis bin labels? [default=l]: ";
  $binlabel = <STDIN>; chomp ($binlabel); 

  $nbin = ($binmax-$binmin)/$binwidth;
  $nbin = 1+sprintf("%d",$nbin);

  for (my $i = 0; $i < $#ar; $i++) {
    $bin_num = ($ar[$i]-$binmin)/$binwidth;
    $bin_num = sprintf("%d",$bin_num);
    for ($k = $bin_num; $k <= $nbin; $k++) {
       $hist[$k] += 1;
     }
  }

#  $hist[$nbin]= 0;
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
    $ctemp = $ymax/12;
    $y_upper = $ymax + sprintf("%d",$ctemp);
    env($binmin, $xx[$nbin], 0, $y_upper,0,0);}
  else {
    env($binmin, $xx[$nbin], 0, $ymax,0,0); }
  label_axes($xlabel,"N(< x)",$title);
  pgbin($nbin, \@xx, \@hist, 1);

  print "\n Write out cumulative histogram values to hist.out? (y/n) : ";
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
  



# sub asin { atan2($_[0], sqrt(1 - $_[0] * $_[0])) }


sub menu {

print "Choose from the following: \n ";
print " 1. Gamma/beta_app histogram for a narrow range of beta_app \n ";
print " 2. Cumulative gamma/beta_app histogram for a narrow range of beta_app \n ";
print " 3. redshift histogram \n ";
print " 4. observed luminosity histogram \n ";
print " 5. observed flux density histogram \n ";
print " 6. Lorentz factor histogram \n ";
print " 7. apparent speed histogram \n ";
print " 8. cumulative apparent speed histogram \n ";
print " 9. viewing angle histogram \n ";
print "10. viewing angle / critical angle histogram \n ";
print "11. cumulative viewing angle / critical angle histogram \n ";
print "12. gamma*sin(theta) histogram \n ";
print "13. cumulative gamma*sin(theta) histogram \n ";
print "14. beta_app*sin(theta) histogram \n ";
print "15. Doppler factor histogram for a narrow range of beta_app \n ";
print "16. beta_app*sin(theta) histogram for a narrow range of beta_app \n ";
print "17. cumulative beta_app*sin(theta) histogram for a narrow range of beta_app \n ";
print "18. gamma*sin(theta) histogram for a narrow range of gamma \n ";
print "19. sin(theta) histogram for a narrow range of gamma \n ";
print "20. theta vs. redshift scatter plot \n ";
print "21. beta_app vs. brightness temperature  plot \n ";
print "22. beta_app vs. apparent luminosity scatter plot \n ";
print "23. beta_app vs. apparent core luminosity scatter plot \n ";
print "24. gamma vs. theta scatter plot \n ";
print "25. Beta_app vs. luminosity density contour plot \n ";
print "26. angular speed histogram \n ";
print "27. angular speed versus log 2 cm VLBA flux density \n ";

print "\n";
print "Choice? [enter 0 to exit] ";
$menuchoice = <STDIN>; chomp ($menuchoice);

return $menuchoice;
}
