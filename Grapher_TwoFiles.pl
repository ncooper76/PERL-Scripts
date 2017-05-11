#!/usr/bin/perl
#
# usage: perl Grapher_TwoFiles.pl 
#
#This is designed to take a single column files and create a 2-D
#scatter plot of the data.
#

use Time::Local;
use Cwd;
use PGPLOT;
use Tie::File;
use Fcntl;


$i = 0; #loop interation index

########################################
#First step is to select the file and
#name the axes of the graph
########################################


print "Select first file would you like to graph? ";

    chomp($file1 = "/home/nathan/scripts/Data/". <STDIN>);

print "Select second file would you like to graph? ";

    chomp($file2 = "/home/nathan/scripts/Data/".<STDIN>);

print "What would you like to call the x-axis? ";

    chomp($x_axis = <STDIN>);

print "What would you like to call the y-axis? ";

    chomp($y_axis = <STDIN>);


########################################
#Next step is to open the file and
#place the data in an array, then
#seperate the x and y variables into
#arrays
########################################

open (DATA1, $file1);

open (DATA2, $file2);

#open (OUT1, ">$var1".'_w_'."$var2.dat");
#open (OUT2, ">$var2".'_w_'."$var1.dat");

chomp(@data1 = <DATA1>);

chomp(@data2 = <DATA2>);

$k = $#data1;
$i = 0;
$j = 0;

while($i<=$k){

    #print "$data1[$i] $data2[$i]\n";
if (($data1[$i] ne 'NULL')&&($data2[$i] ne 'NULL')){
    $x[$j] = $data1[$i];
    $y[$j] = $data2[$i];
    $j++
} 

$i++;
}

    close(DATA1);
    close(DATA2);

########################################
#Finally the x and y arrays are put
#into a PGPLOT graph
#
########################################
$n = $#x+1;  #number of points = number of entries into the array

print "Enter a number (1 to 10) for the data point style: ";

 chomp($k = <STDIN>);

$x_min = &min(@x) - 1;
$y_min = &min(@y) - 1;
$x_max = &max(@x) + 1;
$y_max = &max(@y) + 1;


pgbegin(0,'?',1,1);
pgenv($x_min,$x_max,$y_min,$y_max,0,0);
pgbox('BCNST', 0, 0, 'CNST', 0,0);
pgsch(1.2);
pglabel($x_axis,$y_axis,"");


pgpnts($n,\@x,\@y,$k,0);

#####################################
#Subrourtines for finding max and 
#min valus in an array
#
#####################################

sub max
{ my $max = pop(@_);
foreach (@_)
{ $max = $_ if $_ > $max;
}
$max;
} 


sub min
{ my $min = pop(@_);
foreach (@_)
{ $min = $_ if $_ < $min;
}
$min;
} 

