###############################################
#
# Poly-co-f
# Campagne CoNLL 2011
# E.Charton - École Polytechnique de Montréal
#
###############################################
# conll-expe.pl
# Objet : gestion d'une experience complete
#         traitement du fichier et étiquetage
#         ! Le modèle doit avoir été créé
# 28 fev 2011
# 16 mars 2011
# 30 mars 2011 - stable
# 31 mars 2011 - divers bug + svm
###############################################
require "lib/conll-label.pl";
$metrics = "muc"; ### ou all
$mode = "MENTIONS"; ### open / closed / mentions

###############################################
###### Charger la liste de fichiers
###############################################
my @files = (); ### fichiers à lire
my $outputfile = "\/home\/eric\/conll-st-2011-v1\/output";
my $testlist = "dev_gold.list"; ### Nom et chemin du fichier liste à tester
 
open(in, $testlist) || die "Pas de liste de fichiers à traiter\n";

while(<in>){

	my $a = $_;
	chomp($a);
	$files[@files] = $a;

}


###############################################
# 1 Détecter les corefs dans tous les fichiers
###############################################
for(my $x = 0; $x < @files; $x++){

	my $file = $files[$x];
	my $sortfile = $file; $sortfile =~ s/\/([^\/]+)$//; $sortfile = "$outputfile\/$1";

	label($file, $sortfile, $mode); 
}

###############################################
# 2 Réunir tous les fichiers en un seuls
###############################################
print "[2] Sortie des fichiers agrégés\n";

open(out1, ">$outputfile\/global.reference.conll") || die "Pas de sortie fragment";
open(out2, ">$outputfile\/global.calculated.conll") || die "Pas de sortie";
my $c1 =0; my $c2=0;
for(my $x = 0; $x < @files; $x++){

	my $file = $files[$x];
	my $sortfile = $file; $sortfile =~ s/\/([^\/]+)$//; $sortfile = "$outputfile\/$1";

	### lire fichier d'entrée
	open(frag1, $file) || die "Pas de fragment";
	while(<frag1>){
		my $fragin = $_;
		print out1 "$fragin";
		$c1++;
	}
	close(frag1);

	### lire fichier de sortie
	open(frag2, $sortfile) || die "Pas de fragment";
	while(<frag2>){
		my $fragsort = $_;
		print out2 "$fragsort";
		$c2++;
	}
	close(frag2);

}
close(out1);
close(out2);
print "    $c1-$c2 lines\n";


###############################################
# 3 Mesurer les scores sur le fichier général
###############################################

print "[4] Calcul du score sur sortie Générale\n";
exec("perl ./scorer/scorer.pl $metrics $outputfile\/global.reference.conll $outputfile\/global.calculated.conll ");
print "    perl ./scorer/scorer.pl $metrics $outputfile\/global.reference.conll $outputfile\/global.calculated.conll \n";

