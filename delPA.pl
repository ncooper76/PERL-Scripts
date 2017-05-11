#This program takes .dat files for Kpc and pc jet Position Angles (PA) and calculates
#the difference in PA, delPA.  These data are ordered by source RA and DEC

#open input and output files
open(KPA, "/home/nathan/scripts/Data/KharbEtAl_KpcjetPA.dat"); #Kpc PAs
open(PPA, "/home/nathan/scripts/Data/KharbEtAl_pcjetPA.dat"); #pc PAs
open(DPA, ">/home/nathan/scripts/Data/delPA.dat");

#put input data into arrays

chomp(@Kpc = <KPA>);
chomp(@pc = <PPA>);

$i = 0;  #loop counter

foreach(@pc){

    if($Kpc[$i]!='NULL'){
	
	if($pc[$i]>$Kpc[$i]){
	$delPA[$i] = $pc[$i] - $Kpc[$i];

	if($delPA[$i]<0 && $delPA[$i]>-180){$delPA[$i] = 180 + $delPA[$i];}
	if($delPA[$i]<-180 && $delPA[$i]>-360){$delPA[$i] = 360 + $delPA[$i];}
	if($delPA[$i]>180 && $delPA[$i]<360){$delPA[$i] = 360 - $delPA[$i];}
    }#if pc>Kpc

	if($pc[$i]<$Kpc[$i]){
	$delPA[$i] = $Kpc[$i] - $pc[$i];

	if($delPA[$i]<0 && $delPA[$i]>-180){$delPA[$i] = 180 + $delPA[$i];}
	if($delPA[$i]<-180 && $delPA[$i]>-360){$delPA[$i] = 360 + $delPA[$i];}
	if($delPA[$i]>180 && $delPA[$i]<360){$delPA[$i] = 360 - $delPA[$i];}
    }#if pc<Kpc
      
	}#if
	    elsif($Kpc[$i]=='NULL'){$delPA[$i] = 'NULL';}
    
    print DPA "$delPA[$i]\n";

    $i++;

}#foreach
