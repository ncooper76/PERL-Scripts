#!usr/bin/perl
#This program calculates the trajectory of a baseball 
#with and without air-resistance
#
#

use PDL::Math;
use PGPLOT;

$g = 9.81;   # gravity constant 
$y[0] = 1;      # initial height
$x[0] = 0;      # initial x
$Y[0] = 1;
$X[0] = 0;
$n = 0;          # array index count
$T = 0;          # same
$xmin = 0;   # x axis min.
$xmax = 300; # x axis max.
$ymin = -10.; # y axis min.
$ymax = 100;  # y axis max.

#establish a delta t for the Euler method
print "please select a time interval: \n";
$del_t = <STDIN>; #the euler method time interval
chomp ($del_t);

print "please select initial speed (m/s): \n";
$V = <STDIN>; #the euler method time interval
chomp ($V);

print "please select initial angle (deg): \n";
$theta = <STDIN>; #the euler method time interval
chomp ($theta);
$phi = $theta*3.14159/180;

$Vx = $V*cos($phi); # initial x-velocity
$Vy = $V*sin($phi); # initial y-velocity
$Ux = $V*cos($phi);  # Same as above for friction system
$Uy = $V*sin($phi);  

#print "$Vx,$Vy";

#this sets up the graphing enviroment
pgbegin(0,"/xs",1,1);
pgenv ($xmin,$xmax,$ymin,$ymax,0,0);

#this loop does Euler method for frictionless system
while ($y[$n] >= 0){
    
    $y[$n+1] = $y[$n] + $Vy*$del_t;
    $Vy = $Vy - $g*$del_t;
    $x[$n+1] = $x[$n] + $Vx*$del_t;
    $n += 1;
}

#this graphs the arrays made in the loop
pgpoint ($n+1,\@x,\@y, 2);
    pglabel('x in meters','y in meters','Baseball trajectory');

#$C = 0.5;# A*rho/m  where Rball = 0.363 cm ; rho = 1.2 kg/m^3; Mball = 1 g 

#this loop does Euler method for friction system
while ($Y[$T] >= 0){
    
    $U = ($Ux**2 + $Uy**2)**.5;
    $C = 0.0039 + 0.0058/(1+exp(($U-35)/5));
    $Y[$T+1] = $Y[$T] + $Uy*$del_t;
    $Uy = $Uy - $g*$del_t - $C*$U*$Uy*$del_t;
    $X[$T+1] = $X[$T] + $Ux*$del_t;
    $Ux = $Ux - $C*$U*$Ux*$del_t;
    $T += 1;
    
}

print "$x[$n-1],$y[$n-1];$x[$n],$y[$n] \n $X[$T-1],$Y[$T-1]; $X[$T],$Y[$T] \n";

#this graphs the arrays made in the loop
pgpoint ($T+1,\@X,\@Y, 1);
    pglabel('x in meters','y in meters','Baseball trajectory');
