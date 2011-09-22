###############################################
#
# Campagne CoNLL 2011
# E.Charton - École Polytechnique de Montréal
#
###############################################
# conll-display.pl
# Objet : afficher le contenu d'un fichier
#         avec ses coréréfences
# 9 fev 2011
# dernière v 23 mars 2011 - 
###############################################

require "lib/conll-label.pl";

my $samplefile = "arff/conll-model-05.arff";
my $filelist = "train.gold.list.txt";


###############################################
# Lire les fichiers features
###############################################
print "Loading doc list $filelist\n";
my @thefiles = ();
open( lfil, $filelist ) || die "Pas de liste de fichiers $filelist\n";
while(<lfil>){

	my $lnkf = $_;
	chomp($lnkf);
	$thefile[@thefile] = $lnkf;
}
close( lfil );


###############################################
open(sout,">$samplefile") || die "Impossible d'ouvrir le fichier de sortie\n";

print sout "\@RELATION corefer\n";
print sout "\@ATTRIBUTE dist	REAL\n";
print sout "\@ATTRIBUTE dist-en	REAL\n";
print sout "\@ATTRIBUTE alias 	REAL\n";
print sout "\@ATTRIBUTE similarity 	REAL\n";

print sout "\@ATTRIBUTE C1		REAL\n"; # type entité 1 EN ou autre 
print sout "\@ATTRIBUTE S1		REAL\n"; # Catégorie sémantique 
print sout "\@ATTRIBUTE P1		REAL\n"; # Catégorie PRP
print sout "\@ATTRIBUTE NP1		REAL\n"; # Catégorie NP
print sout "\@ATTRIBUTE DT1		REAL\n"; # Catégorie DT
print sout "\@ATTRIBUTE G1		REAL\n"; # %U=0 M=1 F=2 N=3
print sout "\@ATTRIBUTE Q1		REAL\n"; # %U=0 S=1 P=2 

print sout "\@ATTRIBUTE C2		REAL\n"; # type entité 2 EN ou autre 
print sout "\@ATTRIBUTE S2		REAL\n"; # Catégorie sémantique
print sout "\@ATTRIBUTE P2		REAL\n"; # Catégorie PRP
print sout "\@ATTRIBUTE NP2		REAL\n"; # Catégorie NP
print sout "\@ATTRIBUTE DT2		REAL\n"; # Catégorie DT
print sout "\@ATTRIBUTE G2		REAL\n"; # %U=0 M=1 F=2 N=3
print sout "\@ATTRIBUTE Q2		REAL\n"; # %U=0 S=1 F=2 

print sout "\@ATTRIBUTE class     {0,1}\n";
print sout "\@DATA\n";

###############################################


###############################################
# Boucle de sortie 
###############################################

for(my $v = 0 ; $v < @thefile; $v++){

	my $file = $thefile[$v];

	my $c = 0;
	my $definition = (); ### stockage complet
	my $docmax = 0; ## numéro du document max

	print "Ouverture du document $file\n";
	open(in, $file) || die "Pas de fichier";

	##
	my @stockage = (); ### stockage provisoire


	### collecter les corefs
	while(<in>){

		my $entry = $_;
		chomp($entry);

		### séparation
		$entry =~ s/\s+/\t/g;		

		### split
		my @content = split(/\t/, $entry);
		### dernière
		my $max = @content; $max--;

		## bc/cctv/00/cctv_0001   0    3      Taihang    NNP          (NP*   -   -   -   -           (ORG*       (74
		## bc/cctv/00/cctv_0001   0    4     Mountain    NNP           *)))  -   -   -   -               *)       74)

		### stockage
		$stockage[$c][1] =  $content[1]; ### stocker l'idx de doc
		$stockage[$c][2] =  $content[3]; ### stocker le mot
		$stockage[$c][3] =  $content[10]; ### stocker l'EN
		$stockage[$c][3] =~ s/[\(\)\*]//g;
		$stockage[$c][4] =  $content[$max]; ### stocker la coref
		$stockage[$c][5] =  $content[4]; ### stocker l'étiquette de POS
		$stockage[$c][6] =  $content[5]; ### stocker l'étiquette de NP

		$c++;
	
		if ($content[1] > $docmax ) { $docmax = $content[1]; } ### stocker le doc maximal
	}
	close(in);



	############################################
	### Interpréteur
	############################################
	# S'applique sur un tableau et permet de
	# localiser les en
	my $d = 0;
	my $numax = 0; ## numéro de la plus grande EN.
	
	for ( my $y = 0 ; $y < $c; $y++){


		print "$stockage[$y][1] $stockage[$y][2]          "; 

		# bc/cctv/00/cctv_0001   8    4           Taiwan   NNP    (NP(NP(NP*          -    -   -   -     (GPE)      (ARG0*       (ARG0*   (20|(79
		# bc/cctv/00/cctv_0001   8    5               's   POS             *)         -    -   -   -        *            *            *        79)

		my $en = "";


		### détection d'une fin de phrase
		if ( $stockage[$y][2] =~ /[\.\?\!\;]/ ){

			$definition[$d][0]=-1; ## num de coref, pour phrase = 0
			$definition[$d][2]= $stockage[$y][1]; ### num de document
			$definition[$d][5]= "SENT"; ### REF SENT
			$definition[$d][4]= $y; ### num de ligne
			### 6 gender 7 mode
			$definition[$d][8]= $stockage[$y][6] ; ### SYNTAGME
			$d++;
		}

        	### détection d'un début
		if ( $stockage[$y][4] =~ /\|\(([0-9]+)/ ){

			$en = $stockage[$y][3]; ## sauver EN si elle existe

			my $num = $1; ## sauver le num
			my $z = $y;
			my $name = "";

			while($stockage[$z][4]!~ /$num\)/ ){		

				#### conserver le nom
				$name = $name . "$stockage[$z][2] ";
				$z++;

				#### si une EN est présente dans la boucle
				#### cad qu'elle n'est pas déclarée dans le premier élément (ex Professor Jin Xide)
				if ( $stockage[$z][3] =~ /[A-Z]{2,10}/ ) {
					$en = $stockage[$z][3];

				}
			}
			$name = $name . "$stockage[$z][2] ";
			$name =~ s/\s+$//;### retire espace de fin
			print "[$name $num $en]";

			## Stocker la définition
			$definition[$d][0]= $num; ### num de coref
			$definition[$d][1]= $name; ### texte de coref
			$definition[$d][2]= $stockage[$y][1]; ### num de document
			$definition[$d][3]= $en; ### num de en
			$definition[$d][4]= $y; ### num de ligne
			$definition[$d][5]= $stockage[$y][5]; ### POS
			### 6 gender 7 mode
			$definition[$d][8]= $stockage[$y][6] ; ### SYNTAGME
			$d++;

			## numax de coref
			if ($num > $numax) { $numax = $num;}

		}

		### chercher (num
		### détection d'un début
		if ( $stockage[$y][4] =~ /\(([0-9]+)/ ){

			$en = $stockage[$y][3]; ## sauver EN si elle existe
			my $num = $1; ## sauver le num
			my $z = $y;
			my $name = "";

			while($stockage[$z][4]!~ /$num\)/ ){		

				$name = $name . "$stockage[$z][2] ";
				$z++;


				#### si une EN est présente dans la boucle
				#### cad qu'elle n'est pas déclarée dans le premier élément (ex Professor Jin Xide, Even David Boren -> PERSON)
				if ( $stockage[$z][3] =~ /[A-Z]{2,10}/ ) {
					$en = $stockage[$z][3];
				}

			}
			$name = $name . "$stockage[$z][2] ";
			$name =~ s/\s+$//; ### retire espace de fin
			print "$name($num) $en ";

			## Stocker la définition
			$definition[$d][0]= $num; ### num de coref
			$definition[$d][1]= $name; ### texte de coref
			$definition[$d][2]= $stockage[$y][1]; ### num de document
			$definition[$d][3]= $en; ### ref de en
			$definition[$d][4]= $y; ### num de ligne
			$definition[$d][5]= $stockage[$y][5]; ### POS
			### 6 gender 7 mode
			$definition[$d][8]= $stockage[$y][6] ; ### SYNTAGME
			
			$d++;

			## numax de coref
			if ($num > $numax) { $numax = $num;}


		}

		#### Annuler certaines EN - conformité conll label du 11 mars
		#if ( $en =~ /CARDINAL/ || $en =~ /DATE/ || $en =~ /TIME/ || $en =~ /MONEY/  || $en =~ /PERCENT/ || $en =~ /ORDINAL/ || $en =~ /QUANTITY/ || $en =~ /EVENT/ || $en =~ /NORP/) { $d--; }
		#### Annuler certaines EN - conformité conll label du 21 mars
		#if ( $en =~ /CARDINAL/ || $en =~ /TIME/ || $en =~ /MONEY/  || $en =~ /PERCENT/ || $en =~ /ORDINAL/ || $en =~ /QUANTITY/ ||  $en =~ /NORP/) { $d--; }
		if ( $en =~ /CARDINAL/ || $en =~ /MONEY/  || $en =~ /PERCENT/ || $en =~ /ORDINAL/ || $en =~ /QUANTITY/ ||  $en =~ /NORP/) { $d--; }


		print "\n";
	
	
	}

	print "-$docmax:$numax\n";
	#die;


	############################################
	### Gender and modal attribution
	############################################
	# Dupliquer sur le Train

	for (my $f = 0; $f < $d; $f++){


			## Gender detect
			my $ag, $am; 

			## préparer la séquence pour reconnaissance
			my $sequence = lc($definition[$f][1]);

			#### Péparation
			$sequence =~ s/\'s//g; ## on retire les 's
			$sequence =~ s/\s{2,5}/\s/g; ## on réduit tous les spaces à 1 
			$sequence =~ s/\s+$//g; ## on retire le dernier space


			### séquence complète reconnue en hash
			if ( exists $gender{$sequence} ){
				my $def = gender($gender{$sequence});
				
				$def =~ s/([A-Z])([A-Z])//g;

				$ag = $1; ## Gender 
				$ab = $2; ## mode
				
				### Les EN sont plurielles dans la base. Patching des EN
				if ( $definition[$f][3] =~ /PERSON|ORG|GPE|NORP|LOC|FAC|PRODUCT|WORK\_OF\_ART/  ) { $ab = "S"; }
				### si un 's
				if ( $definition[$f][1] =~ /\'s$/ ) { $ab = "P"; }

				print "---1:$ag:$ab:$definition[$f][1]\n";  

			### sinon détection classique
			}else{

				my $def = genderpron($sequence);
				print "---2:$def:$definition[$f][1]-$f\n";				
				$def =~ s/([A-Z])([A-Z])//g;
				
				$ag = $1; ## Gender 
				$ab = $2; ## mode

			}
			
			### détection des noms de personnes par le prénom
			if ( $ag eq "U" && $definition[$f][3] =~ /PERSON/)
			{
				$ag = gendername($sequence);
				$ab = "S"; ## mode singulier par défaut sur les personnes
			}


			### attribution
			$definition[$f][6] = $ag; ## Gender 
			$definition[$f][7] = $ab; ## Mode

	} 

	#### Nettoyage des features ####
	# She,her,herself ne peut co-référer avec M
	# He,him,himself ne peut co-référer avec F
	my %gendflag = ();
	for (my $f = 0; $f < $d; $f++){
		if ( lc($definition[$f][1]) =~ /^she|^her|^herself/ ) { $gendflag{$definition[$f][0]} = "F"; } 
		if ( lc($definition[$f][1]) =~ /^his|^he |^him|^himself/ ) { $gendflag{$definition[$f][0]} = "M"; } 
	}

	for (my $f = 0; $f < $d; $f++){
		## Si le num de coref correspondant à la ligne courante est déclarée
 		if ( exists $gendflag{$definition[$f][0]} ) {
			$definition[$f][6] = $gendflag{$definition[$f][0]};
		}
	}

	###########################################
	### Production de features
	###########################################

	for (my $s = 0; $s < $docmax+1 ; $s++ ){ ### pour tous les nums de docs
		
		$previous = 0;

		########################################
		# Lire un document
		########################################
		my @thisdoc = (); ### stockage provisoire d'un document
		my $pos = 0;
		for ( my $u = 0 ; $u < $d; $u++) ### pour toutes les lignes
		{

				if ( $definition[$u][2] == $s ) ### si on est dans le bon doc
				{
					### On mémorise le num de doc
					$thisdoc[$pos][20] = $definition[$u][2];

					## Num de doc  : Num de coref : texte de coref 
					## On n'affiche pas les SENT				
					if ($definition[$u][0]>0) { 
						print "Document:$definition[$u][2]/ligne:$definition[$u][4] - Coref=$definition[$u][0]-";
						print "$definition[$u][1]-$definition[$u][3]-$definition[$u][5]-G=$definition[$u][6]-Q=$definition[$u][7]\n"; 
					}
				
					## organisation du stockage provisoire du document
					$thisdoc[$pos][0] = $definition[$u][0]; ### coref num
					$thisdoc[$pos][1] = $definition[$u][3]; ### EN REF
					$thisdoc[$pos][2] = $definition[$u][5]; ### POS REF
					### genre et pluriels	
					$thisdoc[$pos][3] = $definition[$u][6]; ### masc / pluriel	
					$thisdoc[$pos][4] = $definition[$u][7]; ### masc / pluriel	
				
					### Indicateur de ligne pour l'affichage
					$thisdoc[$pos][10] = $definition[$u][4];

					### Chaîne pour comparaison de strings
					$thisdoc[$pos][17] = $definition[$u][1]; ### texte de coref

					#### Le type
					#### Si la séquence n'est pas associée à une entité nommée, alors lui associer une étiquette de POS
					
					if ( ! exists $classes{$thisdoc[$pos][1]} )
					{ 
						$thisdoc[$pos][1] =  $definition[$u][5];

						### conversions 
						my $c = 1;
	
						if ( $thisdoc[$pos][1] =~ /^NN/ ) { $thisdoc[$pos][5] = "NOUN"; $c = 0;}
					
						### détecter la classe de PRP
						elsif ( $thisdoc[$pos][1] =~ /^PRP/ ) { 
							$thisdoc[$pos][5] = "PRP"; $c = 0;
							$prptex = lc($definition[$u][1]);
							
							## Parfois contient une prep et autre chose				
							if (! exists $prpclasses{$prptex} ) { $prptex = "unrek";}

							### on archive la préposition qui correspondra ensuite à un code
							$thisdoc[$pos][15] = $prptex;
							
						}
						elsif ( $thisdoc[$pos][1] =~ /^DT/ ) { 
							$thisdoc[$pos][5] = "NP"; $c = 0;
							
							### Type de determiners
							### http://en.wikipedia.org/wiki/Determiner_%28linguistics%29
							$thisdoc[$pos][16] = "NULL"; ### par défaut 
							if ( lc( $thisdoc[$pos][17] ) =~ /^the\s|^this\s|^that\s|^these\s|^those\s|^this$|^that$|^these$|^those$/ ){ $thisdoc[$pos][16] = "DEM"; } ## Demonstrative 
							if ( lc( $thisdoc[$pos][17] ) =~ /^a\s|^an\s/ ) { $thisdoc[$pos][16] = "DEF"; } ## Indefinite
							if ( lc( $thisdoc[$pos][17] ) =~ /^some|^each|^one|^both|^every|^another/ ) { $thisdoc[$pos][16] = "QUANT"; } ## Quantifier 
							
							#### récupérer le type de DT
							my @docin = split(/ /,  lc($thisdoc[$pos][17]));
							if ( ! exists $npdetect{$docin[0]} ) { $docin[0] = "unrek" ; }
							$thisdoc[$pos][18]= $docin[0]; 
			
						}
					
						if ( $c  ) { $thisdoc[$pos][1] = "OTHER"; $thisdoc[$pos][5] = "EN"; }

						
					}else{

						$thisdoc[$pos][5] = "EN"; ### C'est une EN

					}
				
					#### mettre à NULL ceux qui ne sont pas concernés
					if ($thisdoc[$pos][5] ne "EN"){ $thisdoc[$pos][1] = "NULL"; }
					if ($thisdoc[$pos][5] ne "PRP"){ $thisdoc[$pos][15] = "NULL"; }
					if ($thisdoc[$pos][5] ne "NP"){ $thisdoc[$pos][16] = "NULL"; }

					$pos++;
				}

		}

		########################################
		# Sortir un ARFF
		########################################
	

		for (($i, $j)=(0, $pos) ; $i<$pos ; ($i++,$j--))
		{

				### Flag de doc
				my $crossdoc = 0;

				### Collecter l'entité à faire co-référer
				if ($thisdoc[$j][0] > 0 )
				{

					### Premier num de doc
					my $first_doc = $thisdoc[$j][20];		
	
					### Collecte des caractéristiques de la première entité
					$R = $thisdoc[$j][1];
					my $conum = $thisdoc[$j][0]; ### sauve le numéro de coréférence

					### Variable de gestion des distances
					my $dist = 0; ### Distance en entités
					my $distp = 0; ### Distance en phrases

					### divers
					my $alias = 0;

					### chercher la suivante n fois ###
					my $next = $j;
					my @seqtab = (); ### tableau de stockage provisoire de la chaîne
					my @seqclear = (); ### tableau de stockage provisoire de la chaîne				

					while($next>0)
					{
						$next--;

						### Vérifier des crossdocs
						if ( $thisdoc[$next][20] != $first_doc ) {  $crossdoc = 1; print "Crossdoc:$firstdoc-$thisdoc[$next][20]\n";}	

						### Incrément de phrase
						if ( $thisdoc[$next][2] =~ /SENT/) 
						{ $distp++; }

						if ( $thisdoc[$next][0] > 0 )
						{

							### Les entités sont elles co-référentes
							if ( $thisdoc[$next][0] == $conum )
							{ 
								### même numéro
								$class = 1 ; 

							}
							else 
							{ $class = 0; }

							### %classes =    ( "PERSON" => 1, "GPE"
							$ent1 = $classes{$R}; $ent2 = $classes{$thisdoc[$next][1]};
						
							### genre et temps
							$genre1 = $gmod{$thisdoc[$j][3]};
							$mode1  = $gmod{$thisdoc[$j][4]};
							$genre2 = $gmod{$thisdoc[$next][3]};
							$mode2  = $gmod{$thisdoc[$next][4]};

							### type
							$cotype1 = $classesnum{$thisdoc[$j][5]};
							$cotype2 = $classesnum{$thisdoc[$next][5]};

							### classe de prp
							$prp1 = $prpclasses{$thisdoc[$j][15]};
							$prp2 = $prpclasses{$thisdoc[$next][15]};

							### classe de noun phrase
							$npc1 = $npclasses{$thisdoc[$j][16]};
							$npc2 = $npclasses{$thisdoc[$next][16]};

							### type exact de DT							
							if ( ! exists $npdetect{$thisdoc[$j][18]} )  {    $thisdoc[$j][18] = "NULL"; }
							if ( ! exists $npdetect{$thisdoc[$next][18]} )  { $thisdoc[$next][18] = "NULL"; }
							$dt1 = $npdetect{$thisdoc[$j][18]};
							$dt2 = $npdetect{$thisdoc[$next][18]}; 

							### Substring -> ne concerne que les NP-NP et NP-EN
							if ( ( $thisdoc[$next][5] eq "NP" || $thisdoc[$next][5] eq "EN" )  && ( $thisdoc[$j][5] eq "NP" || $thisdoc[$j][5] eq "EN" ) ){

								$subscompare = substring($thisdoc[$j][17], $thisdoc[$next][17]);
							}else{
								$subscompare = 0; 
							}

							### les entités nommées co-référentes sont elles alias
							### {PERSON,GPE,ORG,LOC,FAC,TIME,WORK_EVENT} 
							if ( $thisdoc[$next][0] == $conum && $thisdoc[$j][5] eq "EN" && $thisdoc[$next][5] eq "EN"){ $alias = 1; } 

							#### Construction de la feature
						        my $sarff = "$dist,$distp,$alias,$subscompare, ";
							$sarff = $sarff .  "$thisdoc[$j][5],$R,$thisdoc[$j][15],$thisdoc[$j][16],$thisdoc[$j][18],$thisdoc[$j][3],$thisdoc[$j][4], ";
							$sarff = $sarff .  "$thisdoc[$next][5],$thisdoc[$next][1],$thisdoc[$next][15],$thisdoc[$next][16],$thisdoc[$next][18],$thisdoc[$next][3],$thisdoc[$next][4], $class"; 

							### séquences numériques
							$arff = "$dist,$distp,$alias,$subscompare, $cotype1,$ent1,$prp1,$npc1,$dt1,$genre1,$mode1, $cotype2,$ent2,$prp2,$npc2,$dt2,$genre2,$mode2,$class";

							### stockage
							$seqtab[@seqtab] = $arff; ### stocker provisoirement la séquence pour le ARFF dans le tableau
							$seqclear[@seqclear] = $sarff; ### stocker provisoirement la séquence commentée dans le tableau
							

							$dist++; 
							### Raz 
							$alias = 0;
				
							#### Bloquer la boucle lorsque l'on à atteint la co-référence -- cad class = 1 (le postérieur est un bruit inutile)
							if ($class == 1 ) {last;} 

						}### fin de if thisdoc

						#### Bloquer la boucle lorsque l'on atteint la portée maxi
						if ($dist == $portee) {last;} 
					

					
					} ### Fin de while


					#### Sortie de la séquence si elle n'est pas cross-doc
					if ( $crossdoc == 0 ){
						#### Sortie de la séquence uniquement si elle a mené à une chaîne complète
						if ( $class == 1 ) { 

							print "----- Sequence $thisdoc[$j][10] --------------\n";
							for(my $g =0; $g < @seqtab; $g++){
								print "$seqtab[$g]      $seqclear[$g]\n";
								print sout "$seqtab[$g]\n";
							}
							print "\n";
							
						}
					}


				} ### Fin de if thisdoc

			
		} ### Fin de for i-j
		print "--------\n";

	}

} ### Fin de boucle for

close(sout);

