#!usr/bin/local/perl
use DBI;

my $galaxy = DBI->connect ("DBI:mysql:galaxies:localhost", "galaxies", "******")

  || die "Couldn't connect to database: ". DBI -> errstr; #connects to database



my $sql_showcol = "SELECT source, epoch FROM epochs"; #makes sql statement

my $table = $galaxy->prepare($sql_showcol);

$table->execute();#sets up a table that will show sources and epochs

while (my($source, $epoch) = $table->fetchrow_array())
{ print "$source ($epoch} \n";}

$table->finish();
$galaxy->disconnect();
exit();
