###############################################
#
# Campagne CoNLL 2011
# E.Charton - École Polytechnique de Montréal
#
###############################################
# conll-label.pl
# Objet : étiqueteur - librairie
# 18 fev 2011
# 7 mars 2011 - compatibilité avec train feat ext
# 11 mars 2011 - bugs - ne traite plus les en num
# 14 mars 2011 - bugs - ajotu these those en NP
# 15 mars 2011 - Détection des DATE et NP
# 16 mars 2011 - Traitement des EN dans uN NP
# 30 mars 2011 - Divers bugs
# 1 avril 2011 - stable - ajoute quelques TIME
# 4 avril 2011 - heuristiques it Michel
# 7 avril JJ dans les 4 qui suivent
###############################################

$version = "0.9";

### Toutes les classes disponibles - utilisés pour attribuer le numéro final
%classesnum =    ( "EN" => 1, "PRP" => 2, "NOUN" => 3, "OTHER" => 4, "NP" => 5  );

### Les classes d'entités nommées et leur numéro correspondant - utilisés pour vérifier que la séquence est une EN
%classes =    ( "NULL" =>0, "PERSON" => 1, "GPE" => 2, "ORG" => 3, "PRODUCT" => 4, "FAC" => 5, "DATE" => 6 , "CARDINAL" => 7, "MONEY" => 8, "NORP" => 9, "QUANTITY" => 10, "LOC" => 11, "WORK_OF_ART" => 12, "EVENT" => 13, "LAW" => 14, "LANGUAGE" => 15,  "TIME" => 16,   "ORDINAL" => 17,  ,  "PERCENT" => 18, "OTHER" => 18 );

### Classes de prépositions
%prpclasses = ( "NULL" =>0, "ourselves" => 1, "they" => 2, "yourself" => 3, "you" => 4,  "ya" => 5, "my" => 6, "we" => 7, "she" => 8, "herself" => 9, "our" => 10, "himself" => 11, "him" => 12, "us" => 13, "his" => 14, "its" => 15, "her" => 16, "i" => 17, "ours" => 18, "he" => 19, "them" => 20, "me" => 21, "themselves" => 22, "your" => 23, "their" => 24, "myself" => 25, "mine" => 26, "itself" => 27, "it" => 28, "my" =>29, "unrek" => 30);    

### Classes de NOUN Phrases - DT 
%npclasses = ( "NULL" =>0, "DEM" =>1, "DEF" =>2, "QUANT" =>3, "OTHER" =>4);

### Classes détection NP
%npdetect = ("NULL" => 0, "the" => 1 ,  "this" => 2, "that" => 3,  "some" => 4,  "these" => 5, "those" => 6, "an" => 7, "a" => 8, "another" => 9, "every" => 10, "all" => 11, "both" => 12, "any" => 13, "each" => 14, "unrek" => 15);
%npdetectbis = ("NULL" => 0, "its" => 1 ); ### Classe de détection complémentaire

### genre et mode
%gmod = ("U" => 0, "M" => 1, "F" => 2, "N" => 3, "S" => 1, "P" => 2); 
$portee = 10; ### en testant la même portée que sur le train


######### Configuration du classifieur
$model =  "model-full-13-ext.model";
$treemodel = "model-treesj48-1.model";
$svmmodel = "model-svm-02.model";
$kx = "svm"; ## tree/svm/neural


###############################################
###### Charger la base de genre
###############################################
print "Loading Gender\n";
my $genderpath = "/home/eric/conll-st-2011-v1/resources/gender.data";
open(gend, "$genderpath") || die "Pas de Gender file";
while(<gend>){
	my $a = $_;
	chomp($a);
	my @split = split(/\t/, $a);
	$gender{$split[0]} = $split[1];
}
### Retirer it et our
delete $gender{"it"};
delete $gender{"our"};
print "Loaded Gender : $genderpath\n";
###############################################



###############################################
#
# Traitement par documents
#
###############################################
sub label{
	my(@args) = @_;
	my $file = $args[0]; 
	my $sortfile = $args[1];
	my $mode = $args[2]; ### CLOSED - OPEN = MENTIONS

	print "-$file\n";
	print "-$sortfile\n";
	print "-$mode\n"; 


	my $c = 0;
	my $definition = (); ### stockage complet
	my $docmax = 0; ## numéro du document max
	print "----------------------------------------------------------\n";
	print "Ouverture du document $file\n";
	print "----------------------------------------------------------\n";
	open(in, $file) || die "Pas de fichier $file\n";

	##
	my @stockage = (); ### stockage provisoire

	############################################
	### collecter les corefs
	############################################	
	while(<in>){

		my $entry = $_;
		chomp($entry);

		### séparation
		$entry =~ s/\s+/\t/g;
	
		###################################################################################
		### pour travailler sur les dev et train, retirer la colonne de coreference de fin
		###################################################################################

		## bn/cnn/00/cnn_0010	0   6	the	 DT        (NP(NP*	-	-	-	-	*	(ARG1*	(19
		## bn/cnn/00/cnn_0010   0   3   us       PRP       (NP*))))     -    -   -   -   *    (ARG1*)   (13)
		## bn/cnn/00/cnn_0010   0   3   us       PRP       (NP*))))     -    -   -   -   *    (ARG1*)
		$entry =~ s/\t\([0-9]+\)$|\t[0-9]+\)$|\t\([0-9]+$//;
		## bn/cnn/00/cnn_0010	0   7	Belgrade NNP	(NP*)))))	-	-	-	-	(GPE)	*	*	(10)|19)
		## bn/cnn/00/cnn_0010	0   11	capital	 NN	*)))	-	-	2	-	*	*)	19)|10)
		$entry =~ s/\t[\(0-9\)]+\|[\(0-9\)\|]+$//;
		## bn/voa/00/voa_0040   0   1   leading  VBG                  *        lead  02   -   -          *       (V*)       *             *            *    -	
		$entry =~ s/\t\-$//; ## retire le tiret à la fin
		

		### split
		my @content = split(/\t/, $entry);
		### dernière
		my $max = @content; $max--;

		## On label donc on ne prend pas la colonne de cluster
		## bn/cnn/00/cnn_0010   0   3         us   PRP       (NP*))))     -    -   -   -   *    (ARG1*)   (13)

		### stockage
		$stockage[$c][1] =  $content[1]; ### stocker l'idx de doc
		
		$content[3] =~ s/[\*]//g; ## retrait char spec du mot
		$stockage[$c][2] =  $content[3]; ### stocker le mot		

		$stockage[$c][3] =  $content[10]; ### stocker l'EN

		# En train et en mode mentions, l'IDX 4 est utilisé pour stocker la ref de coref
		$stockage[$c][4] = $content[$max]; ### stockage de la mention pour le mode mentions

		$stockage[$c][5] =  $content[4]; ### stocker l'étiquette de POS
		$stockage[$c][6] =  $content[5]; ### stocker l'étiquette de NP
		$stockage[$c][10] =  $entry; ### stocker toute la ligne pour restitution
		
		$c++;
	
		if ($content[1] > $docmax ) { $docmax = $content[1]; } ### stocker le doc maximal
	
	}
	close(in);
	print "Fin de lecture de doc, $c lines\n";


	#########################################################
	#
	#
	# 	Identification des mentions candidates
	#
	#
	#########################################################
	my $d = 0;
	my $numax = 0; ## numéro de la plus grande EN.
	my $sepsent = 0;


	############################################
	## Localisation
	############################################
	for ( my $y = 0 ; $y < $c; $y++){

		############ détection d'une fin de phrase ################################################
		if ( $stockage[$y][2] =~ /[\.\?\!\;]/ ){

			$sepsent++; ### a chaque phrase, incrémenter le séparateur
		}

		############ On parcoure tout le fichier et on cherche les entités coréférentes ###########
		
		

		############################################
		#  Identifier les EN                       #
		############################################
		### détection d'un début
		##   bn/cnn/00/cnn_0010   0    7          Belgrade   NNP     (NP*)))))     -    -   -   -    (GPE)     *        *    (10)|19)
		##   bn/cnn/00/cnn_0010   0    1          Foreign    NNP               *              -    -   -   -       (ORG)        *     -
		##   bn/cnn/00/cnn_0010   0    2         Minister    NNP               *)             -    -   -   -          *         *     -
		my $en = "";
		
		if ( $stockage[$y][3] =~ /\(([A-Z]+)\)/ ){ ### stockage simple (EN)

			$en = $1; 
	
			## Stocker la définition
			$definition[$d][0]= 990; ### num de coref EN par défaut
			$definition[$d][1]= $stockage[$y][2]; ### texte de coref
			$definition[$d][1]=~ s/\s+$//;### retire espace de fin
			$definition[$d][11]= $definition[$d][1]; ### archivage du seul texte de coref
		
			$definition[$d][2]= $stockage[$y][1]; ### num de document
			$definition[$d][3]= $en; ### nom de en
			$definition[$d][4]= $y; ### num de ligne
			$definition[$d][5]= $stockage[$y][5]; ### POS
			$definition[$d][8]=1; #### longueur de l'EN

			###############################
			#### Gestion des drapeaux	
			###############################		
			$definition[$d][20]= "EN";  ### Type de classe
			$definition[$d][16]="NULL"; ### type de NP Kind sur Null 
			$definition[$d][17]="NULL"; ### mettre classe PRP à NULL
			$definition[$d][22]= "NULL"; ### par défaut le DT est non référencé

			$sepphrase[$d]= $sepsent; ### archiver le nombre de SENT rencontré
			
			#$d++;

		}
		##   bn/cnn/00/cnn_0010   0    3             Igor    NNP               *              -    -   -   -   (PERSON*         *     -
		##   bn/cnn/00/cnn_0010   0    4           Ivanov    NNP               *)             -    -   -   -          *)        *)    8)
		if ( $stockage[$y][3] =~ /\(([A-Z]+)\*/ ){ ### stockage complexe (EN)

			$en = $1; my $lenen = 1; ### longueur de l'EN
			my $z = $y;
			my $name = "";

			while($stockage[$z][3]!~ /\*\)/ ){		

				#### conserver le nom
				$name = $name . "$stockage[$z][2] ";
				$z++;
				$lenen ++;

				#### si une EN est présente dans la boucle
				#### cad qu'elle n'est pas déclarée dans le premier élément (ex Professor Jin Xide)
				#if ( $stockage[$z][3] =~ /\(/ ) {
				if ( $stockage[$z][3] =~ /[A-Z]{2,10}/ ) {

					$en = $stockage[$z][3];
				}
			}
			$name = $name . "$stockage[$z][2]";
			$name =~ s/\s+$//;### retire espace de fin
			

			## Stocker la définition
			$definition[$d][0]= 990; ### num de coref EN par défaut
			$definition[$d][1]= $name; ### texte de coref
			$definition[$d][11]= $name; ### archivage du seul texte de coref
			$definition[$d][2]= $stockage[$y][1]; ### num de document
			$definition[$d][3]= $en; ### nom de en
			$definition[$d][4]= $y; ### num de ligne
			$definition[$d][5]= $stockage[$y][5]; ### ref de premier POS
			$definition[$d][8]= $lenen; #### longueur de l'EN

			###############################
			#### Gestion des drapeaux	
			###############################	
			$definition[$d][20]="EN"; ### Classe EN
			$definition[$d][16]="NULL";### Mettre NP Kind a NULL
			$definition[$d][17]="NULL"; ###mettre classe PRP à NULL
			$definition[$d][22]="NULL"; ### par défaut le DT est non référencé

			$sepphrase[$d]= $sepsent; ### archiver le nombre de SENT rencontré

			#$d++;


		}

		############################################
		###### Corrections sur EN          #########
		############################################
		if ( $en) {

			
			#############################################
			#### Correction des longueurs de séquence
			#############################################
			# Par les suivantes :
			# 's doit être ajouté
			#
			if ($stockage[$y+1][2] =~ /'s/){
				$definition[$d][1] = $definition[$d][1] . " " . $stockage[$y+1][2]; ### ajout le 's à la fin
				$definition[$d][8]++; ### Longuer incrémentée
			}

			### chercher le début du NP si PERSON			
			if ( $stockage[$y][6] !~ /\(NP/ && $en =~ /PERSON/ ){
				my $trackNP = 1;
				
				#### on remonte jusqu'à 10 en arrière
				for ( my $l = 0; $l < 10; $l++ ) {
					
					### on a trouvé un séparateur de syntagme, on arrête				
					if ( $stockage[$y-$trackNP][5] =~ /[\.\,]/ ){  
						last;
					}

					### on a localisé le début du NP
					if ( $stockage[$y-$trackNP][6] =~ /\(NP/ ){  
														
							my $debutEN = $y-$trackNP;
			 				my $finEN = $y;
							my $addEN = ""; 
							### on reconstruit l'EN
							for ( my $m = $debutEN; $m < $finEN; $m++){
								$addEN = $addEN . " " . $stockage[$m][2]; ### ajout le terme devant (ex, Mr, Président, The)
							}
							$definition[$d][1] = $addEN . " " . $definition[$d][1]; 
							$definition[$d][1] =~ s/\s+//;

							$definition[$d][4] =  $debutEN ; ### num de ligne de début décrémenté
							$definition[$d][8]+=  $trackNP; ### Longueur incrémentée
							
							last; ### on sort de la boucle

					}else{
						$trackNP++;
					}
					
				} 
			}
			### remonter

			$d++;

			#############################################
			#### Annuler certaines EN
			#############################################
			if ( $en =~ /CARDINAL/ || $en =~ /MONEY/  || $en =~ /PERCENT/ || $en =~ /ORDINAL/ || $en =~ /QUANTITY/ || $en =~ /NORP/) { $d--; }

			##############################################################
			### les EN Time sont sélectives
			### On ne conserve que celles qui sont gérables facilement
			##############################################################			
			if ( $en =~ /TIME/ ){
				if ( lc($definition[$d-1][1]) !~ /night|midnight|tonight|evening|morning|afternoon|overnight/ ) 
				{ 
					$d--; 
				}
			}

		}

		############################################
		#  Régles de détection                     #
		############################################
		############################################
		#  Identifier les PRP                      #
		############################################
		# bn/cnn/00/cnn_0010   0   2      our   PRP$              (NP*   -   -   -   -        *    (13)
		# bn/cnn/00/cnn_0010   0    8     his   PRP$            (NP*              -    -   -   -          *         *    (5)
		if ( $stockage[$y][5] =~ /PRP/ ){ 

			## Stocker la définition
			$definition[$d][0]= 900; ### num de coref prp par defaut
			$definition[$d][1]= $stockage[$y][2]; ### texte de coref
			$definition[$d][11]= $definition[$d][1]; ### archivage du seul texte de coref
			$definition[$d][2]= $stockage[$y][1]; ### num de document
			$definition[$d][3]= "PRP"; ### nom de en
			$definition[$d][4]= $y; ### num de ligne
			$definition[$d][5]= $stockage[$y][5]; ### POS
			$definition[$d][8]= 1; #### longueur de l'EN

			$definition[$d][20]="PRP"; ### Classe PRP
			$definition[$d][3]="NULL"; ### mettre EN à NULL
			$definition[$d][16]="NULL"; ### Mettre NP Kind a NULL
			$definition[$d][17]= lc($definition[$d][1]); ### ID PRP (texte)
			$definition[$d][22]= "NULL"; ### par défaut le DT est non référencé

			## Parfois contient une prep et autre chose				
			if (! exists $prpclasses{$definition[$d][17]} ) { $definition[$d][17] = "unrek";}


			$sepphrase[$d]= $sepsent; ### archiver le nombre de SENT rencontré
			
			## fin ###
			$d++;


			##########################################
			# Filtrages
			##########################################

			### it ... that
			### On n'oblige pas que "it" soit suivi de BE
			my $win = 6;
			### On restreint la fenêtre à $win mots 
			if ( lc($stockage[$y][2]) =~ /^it/  ){

				#### that dans les $win qui suive
  				for (my $q = 1; $q < $win; $q++)		     
  			 	{
   				   if ( lc($stockage[$y+$q][2]) =~ /^that/ && $stockage[$y+$q][5] =~ /IN/ ) {
        			   		$d--;
						last;
     					 }
  				 }

			}

			### it ... TO
			if ( lc($stockage[$y][2]) =~ /^it/ && lc($stockage[$y+1][2]) =~ /^is|was|'s|seems/ ){
			   			
				for (my $q = 2; $q < $win; $q++)		     
   				{
      					if ( lc($stockage[$y+$q][2]) =~ /^to/ ) {
           					$d--;
						last;
      					}
   				}
			}

			### it ... WHO
			if ( lc($stockage[$y][2]) =~ /^it/  && lc($stockage[$y+1][2]) =~ /^is|was|'s/ ){
 			 
				for (my $q = 2; $q < $win; $q++)		     
   				{
   				   	if ( lc($stockage[$y+$q][2]) =~ /^who/ ) {
        				   	$d--;
						last;
      					}
   				}
			}

			### it BE BECAUSE
			if ( lc($stockage[$y][2]) =~ /^it/  && lc($stockage[$y+1][2]) =~ /^is|was|'s/ &&  lc($stockage[$y+2][2]) =~ /because/ ){
           			$d--;
			}



			### all of us, all of you
			if ( lc($stockage[$y][2]) =~ /^all/ && lc($stockage[$y+1][2]) =~ /^of/ && ( lc($stockage[$y+2][2]) =~ /^us/ || lc($stockage[$y+2][2]) =~ /^you/) ){
				$d--;
			}
			
		}
		
	
		############################################
		#  Identifier les DT- Syntagmes		   #
		############################################
		### Cas  this    DT      (S(NP*)	

		#bn/cnn/00/cnn_0010   0    4               the    DT      (NP(NP*      -    -   -   -       *      *        *        (19
		#bn/cnn/00/cnn_0010   0    5           streets   NNS            *)     -    -   -   -       *      *        *          -
		#bn/cnn/00/cnn_0010   0    6                of    IN         (PP*      -    -   -   -       *      *        *          -
		#bn/cnn/00/cnn_0010   0    7          Belgrade   NNP     (NP*)))))     -    -   -   -    (GPE)     *        *    (10)|19)

		if ( $stockage[$y][5] =~ /DT/ ){ 

			my $name = ""; my $lenen = 1; 
			my $z = $y;
			$name = $stockage[$z][2] . " ";
			$z++;

			### Chercher la suite
			while($stockage[$z][6]!~ /\*\)/ ){		

				#### conserver le nom
				$name = $name . "$stockage[$z][2] ";
				$z++;				
				$lenen ++;
			}

			$name = $name . "$stockage[$z][2] ";
			$name =~ s/\s+$//;### retire espace de fin
			
			## Stocker la définition
			$definition[$d][0]= 1010; ### num de coref DT Par defaut
			$definition[$d][1]= $name; ### texte de coref
			$definition[$d][11]= $name; ### Archivage en cas de transformations et DT
			$definition[$d][2]= $stockage[$y][1]; ### num de document
			$definition[$d][4]= $y; ### num de ligne
			$definition[$d][5]= $stockage[$y][5]; ### ref de premier POS
			$definition[$d][8]= $lenen+1; #### longueur de l'entité

			$definition[$d][20]= "NP"; ### Classe NP
			$definition[$d][3] = "NULL"; ### mettre EN à NULL
			$definition[$d][17]= "NULL"; ###mettre classe PRP à NULL
			$definition[$d][16]= "NULL"; ### Par défaut
			$definition[$d][22]= "NULL"; ### par défaut le DT est non référencé

			### identification du NP Kind ($npclass)
			### http://en.wikipedia.org/wiki/Determiner_%28linguistics%29			
			if ( lc($definition[$d][1]) =~ /^the\s|^this\s|^that\s|^these\s|^those\s|^this$|^that$|^these$|^those$/ ) { $definition[$d][16]  = "DEM"; } ## Demonstrative 
			if ( lc($definition[$d][1]) =~ /^a\s|^an\s/ ) { $definition[$d][16]  = "DEF"; } ## Indefinite
			if ( lc($definition[$d][1]) =~ /^some|^each|^one|^both|^every|^another/ ) { $definition[$d][16] = "QUANT"; } ## Quantifier

			#### récupérer le type de DT ($npdetect)
			my @docin = split(/ /,  lc($definition[$d][1]));
			$definition[$d][22] = $docin[0]; 
			if ( ! exists $npdetect{$docin[0]} ) { $definition[$d][22] = "unrek"; } ### Si non reconnu


			### archiver le nombre de SENT rencontré
			$sepphrase[$d]= $sepsent; 

			$d++; ### Valider le DT 

			##########################################
			# Filtrages
			##########################################
			
			### si le syntagme est une EN (premier mot The = EN) retirer
			if ($stockage[$y][3] =~ /[A-Z]+/) { $d--; }

			### Each - all - any - no - every
			if ( lc($definition[$d-1][1]) =~ /^each|^all|^any|^no|^every/ ) { $d--; }

			
		}
		
	} ### Fin de FOR y => Identification des candidats


	#########################################################
	#
	#
	# 	Sélection des candidats identifiés
	#
	#
	#########################################################
	
	############################################
	# Clusterings des EN et des NP 
	############################################

	my $ckc = 0; ### clustercount	
	my %hashclus = (); ### Hash des |clusters|



	############################################
	### Clustering et conservation des
	### dates
	### Seuls les similaires sont gardés
	############################################

	print "-------- Clustering de DATES ---------\n";
	my %datevalues = ();### stockage des dates décodées

	#### Normaliser les dates
	for (my $e = 0; $e < $d; $e++){
		
		### dates
		if ( $definition[$e][20] eq "EN" && $definition[$e][3] =~ /DATE/ )
		{
			#### mettre à non valide par défaut
			$definition[$e][0]= 1010;

			#### tester les cas
			if ( lc($definition[$e][1]) =~ /today/){
				$datevalues{$e} = 1;  ### today = 1;
 			}	
			if ( lc($definition[$e][1]) =~ /tomorrow/){
				$datevalues{$e} =  2; ### tomorow = 2;
			}	
			if ( lc($definition[$e][1]) =~ /yesterday/){
				$datevalues{$e} =  -1; ### yesterday = -1;
			}		
			if ( lc($definition[$e][1]) =~ /last month/){
				$datevalues{$e} =  -30; ### mois passé = -30;
			}		
			if ( lc($definition[$e][1]) =~ /next month/){
				$datevalues{$e} =  30; ### mois suivant = -30;
			}	

			### années
			if ( $definition[$e][1] =~ /([12][0-9]+)/){
				$datevalues{$e} = $1; ### année = 1984;
			}
			if ( $definition[$e][1] =~ /([56789][0-9])/){
				$datevalues{$e} = "19" . $1; ### année = '68;
			}	
		}
	}	

	#### Normaliser les dates
	for (my $e = 0; $e < $d; $e++){

		### flag sur activation du compteur de clusters		
		my $ckcvalided = 0;

		### dates
		if ( $definition[$e][20] eq "EN" && $definition[$e][3] =~ /DATE/ && exists $datevalues{$e} )
		{	
			### Si il y a une date dans la position courante
			for (my $f = $e + 1; $f < $d; $f++)
			{
					
				if ( $definition[$f][20] eq "EN" && $definition[$f][3] =~ /DATE/ && $datevalues{$e} == $datevalues{$f} )
				{
					$definition[$e][0] = $ckc;
					$definition[$f][0] = $ckc;
					$ckcvalided = 1;
				}					
			}
		}
		
		if ($ckcvalided) { $ckc++;}
	}

	############################################
	### Clustering et conservation des
	### syntagmes NP
	### Seuls les similaires sont gardés
	############################################

	print "-------- Clustering de syntagmes NP ---------\n";
	my $npscore = 0.49; #### seuil de décision -> à partir de quel proba de similarité (hors préposition), on conserve.

	for (my $e = 0; $e < $d; $e++){

		### On clusterise les NP par comparaison, sauf les DEF (indefinis) 
		if ( $definition[$e][20] eq "NP" && $definition[$e][16] ne "DEF" )
		{

			my $first = normalize($definition[$e][1]);
			#print "$e:$first:$definition[$e][0]\n";

			######## Comparaisons
			for (my $f = $e + 1; $f < $d; $f++){

				### Normaliser
				my $second = normalize($definition[$f][1]);
				### comparer
				my $score = substring($first, $second);

				### Si le score de similarité est atteint, si ne sont pas déja égaux et si tous 2 des NP
				if ( $score > $npscore && $definition[$f][20] eq "NP" ) 
				{

					if ($definition[$e][0] == 1010)
					{
						$definition[$e][0] = $ckc;
						$ckc++;
					}
						
					$definition[$f][0] = $definition[$e][0];
					#print "   f=$f [$first:$second] - ckc=$definition[$f][0] sc=$score\n";;

				}
			}
		}
	}	

	####### Retrait de tous les syntagmes non reconnus

	############################################
	### Clustering par pile (Algo INLG 11)
	### Recherche des Alias pour les EN
	############################################
	## Définition
	#			$definition[$d][0]= 99; ### num de coref
	#			$definition[$d][1]= $stockage[$y][2]; ### texte de coref
	#			$definition[$d][2]= ### num de document
	#			$definition[$d][3]= $en; ### nom de en -> ne prend ici que PERSON - ORG - GPE - NORP - LOC
	#			$definition[$d][4]= $y; ### num de ligne
	#			$definition[$d][5]= POS
	#			$definition[$d][6]= gender F M N UK
	

	print "-------- Numérotation et Clustering EN par égalité stricte ---------\n";

	#############################################################
	### Premier passage -> uniquement les égalités strictes
	###
	### On applique sur la séquence d'origine contenue dans $definition[$d][11]
	### $definition[$d][1] contient tout le DT
	#############################################################
	for (my $e = 0; $e < $d; $e++){

		### on ne prends que les 990 qui sont les [EN] non encore coréférées
		if ( $definition[$e][0] == 990 && $definition[$e][20] eq "EN"  )
		{


			### Initialisation du numéro d'EN
			$definition[$e][0] = $ckc; 
			$hashclus{$ckc}++;

			### On initialise une recherche
			my $first = normalize($definition[$e][11]); ## Archive le texte
			
			#print "$e-$first-$ckc-[$definition[$e][0]]\n";

			############################################
			######## Comparaisons
			############################################
			for (my $f = $e + 1; $f < $d; $f++){

				### a comparer			
				my $second = normalize($definition[$f][11]);

				### comparaison en désodre (Jules Guesde - Guesde Jules)
				my $compa = substring($first,$second);

				if ($compa == 1){
					#print "   $f---->$first-$second-$ckc [shak]$compa\n";
					$definition[$f][0] = $ckc;
					$hashclus{$ckc}++;
				}
				

			}

			### passe 2 
			$ckc++;
			
		}## fin de if
	}## fin de for

	#############################################################
	### chercher les subsets des EN
	#############################################################
	### Ex cole -> uss cole
	###    bin laden -> osama bin laden
	###
	### On ne le fait que pour les subsets isolés
	###
	print "-------- Clustering EN par pile et subsets---------\n";
	for (my $e = 0; $e < $d; $e++){

		### On initialise une recherche
		my $first = normalize($definition[$e][11]); ## Archive le texte
		
		#print "$e:$first:CN=$definition[$e][0]\n";

		for (my $f = 0; $f < $d; $f++){
			
			### tester les EN
			### si les 2 sont des EN, et si pas la meme ligne, et si refs des EN différentes, et si EN isolée
			if ( $definition[$e][20] eq "EN" && $definition[$f][20] eq "EN" && $e != $f && $definition[$e][0] != $definition[$f][0] && $hashclus{$definition[$f][0]} == 1 )
			{
				my $second = normalize($definition[$f][11]);
			
				### si second est élément de first
				### attribuer le numéro de second à first
								
				### Prévoir -> yemen != yemeni en encadrant par des espaces
				my $a = " " . $first  . " "; 	
				my $b = " " . $second . " ";
				
				### valable pour tout
				### si b est plus petit que a -> a=uss cole b=cole
				if ( $a =~ /$b/ ){

					$definition[$e][0] = $definition[$f][0];
					#print "    --a>b->$f:$second:new KN=$definition[$e][0]\n";
				}

				### valable uniquement pour les identiques 
				
				### PERSON
				### si b est plus grand que a -> a=bin laden b=ussama bin laden
				if ( $b =~ /$a/ && $definition[$f][3] =~/PERSON/ && $definition[$e][3] =~/PERSON/){

					$definition[$e][0] = $definition[$f][0];
					#print "    -PERS-b>a->$f:$second  new KN=$definition[$e][0]\n";
				}

				### LOC|GSP|DATE
				### si b est plus grand que a -> a=hong kong b=hong kong island
				if ( $b =~ /$a/ && $definition[$f][3] =~/LOC|GPE|DATE/ && $definition[$e][3] =~/LOC|GPE|DATE/){

					$definition[$e][0] = $definition[$f][0];
					#print "    -LOC|GPE-b>a->$f:$second  new KN=$definition[$e][0]\n";
				}


				### EVENT
				### si b est plus grand que a -> Katrina - Katrina huricane
				if ( $b =~ /$a/ && $definition[$f][3] =~/EVENT/ && $definition[$e][3] =~/EVENT/){

					$definition[$e][0] = $definition[$f][0];
					#print "    -LOC-b>a->$f:$second  new KN=$definition[$e][0]\n";
				}

			} 

		}		
	}

	#############################################################
	### chercher les isolés très similaires
	#############################################################
	### Ex hong kong - the honkgong island (n'est pas un subset) 
	###
	print "-------- Clustering EN par similarité---------\n";

	###########################################
	### Chercher les sigles  
	###########################################


	###########################################
	### Retirer tous les inutiles 
	###########################################
	my $newd = 0; ### nouvelle variable de stockage d provisoire 
	my @newdefinition = (); ### nouveau tableau de definition provisoire	

	for (my $e = 0; $e < $d; $e++){

		### Traitement de DT
		### si identité de coref différente de 1010 - qui est le non indexé - DT ou DATE - conserver 
		if ( $definition[$e][0] != 1010 )
		{
			### transférer
			for (my $g = 0; $g< 23; $g++){

				$newdefinition[$newd][$g] = $definition[$e][$g];  
			}
			$newd++;
		}

		### Traitement des dates

	}
	### retransférer
	$d = $newd;
	for (my $e = 0; $e < $d; $e++){
		### transférer
		for (my $g = 0; $g< 23; $g++){
			$definition[$e][$g] = $newdefinition[$e][$g];  
		}
	}


	############################################
	### Gender and modal attribution
	############################################
	for (my $f = 0; $f < $d; $f++){

			## Gender detect
			my $ag, $am; 

			## préparer la séquence pour reconnaissance
			my $sequence = lc($definition[$f][11]); ### On cherche sur la séquence originale non comprise dans un NP

			#### Péparation
			$sequence =~ s/\'s//g; ## on retire les 's
			$sequence =~ s/\s{2,5}/\s/g; ## on réduit tous les spaces à 1 
			$sequence =~ s/\s+$//g; ## on retire le dernier space


			### séquence complète reconnue en hash
			if ( exists $gender{$sequence} ){
				my $def = gender($gender{$sequence});
				#print "---1:$def:$sequence:$definition[$f][1]-$f\n";
				$def =~ s/([A-Z])([A-Z])//g;

				$ag = $1; ## Gender 
				$ab = $2; ## mode
				
				### Les EN sont plurielles dans la base. Patching des EN
				if ( $definition[$f][3] =~ /PERSON|ORG|GPE|NORP|LOC|FAC|PRODUCT|WORK\_OF\_ART/  ) { $ab = "S"; }
				### si un 's
 			        if ( $definition[$f][1] =~ /'s$/ ) { $ab = "P"; }

			### sinon détection classique
			}else{

				my $def = genderpron($sequence);
				#print "---2:$def:$sequence:$definition[$f][1]-$f\n";				
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



	############################################
	### Option intégration NLGbAse 
	### Clustering identité sémantique
	### ( inclut genre et mode)
	############################################
	## Dist real (beg=0), Dist en, alias 0/1, R1, G1, Q1, R2, G2, Q2         

	open(nout,">temp.neuron.arff") || die "Impossible d'ouvrir le test neural provisoire«n";
	print nout "\@RELATION corefer\n";
	print nout "\@ATTRIBUTE dist	REAL\n";
	print nout "\@ATTRIBUTE dist-en	REAL\n";
	print nout "\@ATTRIBUTE alias 	REAL\n";
	print nout "\@ATTRIBUTE similarity 	REAL\n";

	print nout "\@ATTRIBUTE C1		REAL\n"; # type entité 1 EN ou autre 
	print nout "\@ATTRIBUTE S1		REAL\n"; # Catégorie sémantique 
	print nout "\@ATTRIBUTE P1		REAL\n"; # Catégorie PRP
	print nout "\@ATTRIBUTE NP1		REAL\n"; # Catégorie NP
	print nout "\@ATTRIBUTE DT1		REAL\n"; # Catégorie DT
	print nout "\@ATTRIBUTE G1		REAL\n"; # %U=0 M=1 F=2 N=3
	print nout "\@ATTRIBUTE Q1		REAL\n"; # %U=0 S=1 P=2 

	print nout "\@ATTRIBUTE C2		REAL\n"; # type entité 2 EN ou autre 
	print nout "\@ATTRIBUTE S2		REAL\n"; # Catégorie sémantique
	print nout "\@ATTRIBUTE P2		REAL\n"; # Catégorie PRP
	print nout "\@ATTRIBUTE NP2		REAL\n"; # Catégorie NP
	print nout "\@ATTRIBUTE DT2		REAL\n"; # Catégorie DT	
	print nout "\@ATTRIBUTE G2		REAL\n"; # %U=0 M=1 F=2 N=3
	print nout "\@ATTRIBUTE Q2		REAL\n"; # %U=0 S=1 F=2 

	print nout "\@ATTRIBUTE class     {0,1}\n";
	print nout "\@DATA\n";


	## En partant de la fin 	
	for ( (my $u, $v) = (1, $d - 1) ; $u < $d; ($u++, $v--)) ### pour toutes les lignes		
	{
		#print "%%%%%%%%% Traite entité ligne $definition[$v][4]\n";
		print nout "%%%%%%%%% Traite entité ligne $definition[$v][4]\n";
	
		### entité 1 
		my $C1 = $classesnum{$definition[$v][20]}; ### Définir la catégorie : EN, PRP, NP, NOUN, OTHER

		my $S1 = $classes{$definition[$v][3]}; ## type sémantique de l'entité si C = EN
		my $P1 = $prpclasses{$definition[$v][17]}; ## type PRP de l'entité si C=PRP
		my $NP1 = $npclasses{$definition[$v][16]}; ## type NP de l'entité si C=NP

		my $G1 = $gmod{$definition[$v][6]}; ## genre de l'entité
		my $Q1 = $gmod{$definition[$v][7]}; ## mode de l'entité

		my $memtext1 = $definition[$v][1]; ## libellé du texte pour comparaison

		my $dt1 = $npdetect{$definition[$v][22]};


		### Faire les itérations
		my $locpos = 1;
		my $disten = 0; ### distance de première EN
		my $debut = $v;

		while( $locpos < $portee  ){

			### Position
			my $itepos = $v - $locpos;

			### entité 2
			my $C2 = $classesnum{$definition[$itepos][20]}; ### Classe

			my $S2 = $classes{$definition[$itepos][3]}; ## type sémantique de l'entité si EN
			my $P2 = $prpclasses{$definition[$itepos][17]}; ## type PRP de l'entité si C=PRP
			my $NP2 = $npclasses{$definition[$itepos][16]}; ## type NP de l'entité si C=NP

			my $G2 = $gmod{$definition[$itepos][6]};  ## genre de l'entité
			my $Q2 = $gmod{$definition[$itepos][7]};  ## mode de l'entité	

			### type exact de DT
			my $dt2 = $npdetect{$definition[$itepos][22]}; 

			### pourcentage de proximité -> similarity attribute
			### ne s'applique que sur les NP 
			#if ( $definition[$itepos][20] eq "NP" && $definition[$v][20] eq "NP" ){
			
			### Synchronisation avec le train
			if ( ( $definition[$itepos][20] eq "NP" || $definition[$itepos][20] eq "NE" )  && ( $definition[$v][20] eq "NP" || $definition[$v][20] eq "NE" ) ){
			
				$similarity = substring($memtext1, $definition[$itepos][1]);
	
			}else { $similarity = 0; }		

			### Affectation de la valeur d'Alias pour les corefs déja numérotées
			$alias = 0;			
			if ($definition[$v][0] == $definition[$itepos][0] && $definition[$v][0] < 900 ) { $alias = 1; }

			### phrases passées
			my $dist = $sepphrase[$v] - $sepphrase[$itepos];
			
			### Sortir la data courante
			#print "$definition[$v][1] $definition[$itepos][1] ->$disten,$dist,  $alias,$similarity  $C1($definition[$v][20]),$S1,$P1,$NP1,$dt1($definition[$v][22]),$G1,$Q1  
			#$C2($definition[$itepos][20]),$S2,$P2,$NP2,$dt2($definition[$itepos][22]) ,$G2,$Q2  0\n";
			print nout "$disten,$dist,$alias,$similarity, $C1,$S1,$P1,$NP1,$dt1,$G1,$Q1, $C2,$S2,$P2,$NP2,$dt2,$G2,$Q2,0\n";
 
			if ($itepos == 0 ) {last;} 

			$disten++; 
			$locpos++;
		}

	}

	close(nout);



	#####################################
	### lance le classifieur
	#####################################
	
	### classifier arbre
	if ($kx eq "tree") {
		$w = "java -Xmx1024M  weka.classifiers.trees.J48 -l /home/eric/conll-st-2011-v1/models/$treemodel -T /home/eric/conll-st-2011-v1/temp.neuron.arff -p 0 -distribution >temp.neuron.labeled.arff";
	} 
	if ($kx eq "neural")
	{
	### classifier perceptron
		$w = "java -Xmx1024M weka.classifiers.functions.MultilayerPerceptron -l /home/eric/conll-st-2011-v1/models/$model -T /home/eric/conll-st-2011-v1/temp.neuron.arff -p 0 -distribution >temp.neuron.labeled.arff";
	}
	if ($kx eq "svm")
	{
	### classifier SVM
		$w = "java -Xmx1024M  weka.classifiers.functions.LibSVM -l /home/eric/conll-st-2011-v1/models/$svmmodel -T /home/eric/conll-st-2011-v1/temp.neuron.arff -p 0 -distribution >temp.neuron.labeled.arff";
	}
	

	print "$w\n";
   	system "$w";

	### Recharge le fichier de résultats
	open(inn, "temp.neuron.labeled.arff") || die "Pas de fichier d'étiquetage";

	my @results = (); ### tableau de stockage des résultats

	while(<inn>){

		my $a = $_;
		$a =~ s/\s+/\t/g;
	
		my @line = split(/\t/, $a);
		### Read line of predicted test data
		if ( $line[1] =~ /[0-9]/ ){
			my $lcol = @line;
			my $proba = $line[$lcol-1];
		
			### num de test - résultat - proba
			#print "->$line[1]-$line[3]-$proba\n";

			### proba que ça co-réfère
			### *0.898,0.102
			my $probacoref = $proba;
			$probacoref =~ s/\*//g;
			$probacoref =~ s/[\*0-9\.]+,([0-9\.]+)/$1/g;
			$results[@results] = $probacoref;
		}
		
	}
	close(inn);

	############################################
	### Sélection de la meilleure proba
	############################################
	print "------ Association des tables de co-références, argmax proba -----\n";

	#### On explore le tableau des scores à l'envers pour les mettre em rapport avec les co-refs
	my $fin = @results - 1; ## dernier résultat
	my $amnt = 1; ### au début 1 résultat puis incrément


	for ( my $u = 0 ; $u < $d; $u++) ### pour toutes les lignes
	{

		## Num de doc  : Num de coref : texte de coref 
		print "$u:Document:$definition[$u][2]/ligne:$definition[$u][4] - Coref=$definition[$u][0]-$definition[$u][1]-$definition[$u][3]-$definition[$u][5]\]  \[$definition[$u][6]-$definition[$u][7]\] ";

		### Ajouter la liste co-référente au doc affiché
		my $bestchoice = -1; my $bestchoicevalue = 0; ## Variables de sélection
		my $seuil = 0.5; ### seuil de détection

		for (my $h=0; $h < $amnt -1 ; $h++){

			print "[$results[$fin]] ";
			
			#### identification de la paire
			#### si la valeur est supérieure à seuil, coréfère, si supérieure la plus récente
			if ($results[$fin] > $seuil  ) 
			{
				$bestchoicevalue = $results[$fin];
				$bestchoice = $amnt-$h-1 ; 
				
			}
				
			### décrément
			$fin--;

		}
		if ($amnt< $portee ) { $amnt++; }

		### Archivage de l'index		
		my $offu = $u - $bestchoice; ### index of coreferent
		if ($bestchoice != -1) { $definition[$u][30] = $offu; } else { $definition[$u][30] = -1; }

		#######################################
		# Filtrage
		#######################################

		### ne pas prendre en compte le calcul 
		### d'antécédent pour les Indefinite (DEF) -> a, an
		if ( $definition[$u][16] =~ /DEF/ ) { $definition[$u][30] = -1; print "  [[ne pas traiter les INDEF]]  "; }


	
		### Verbose
		### Affichage de l'offset
		print "   bestnum:$bestchoice | $definition[$u][30]";
		print "\n";

	}
	


	############################################
	### Union et numérotation des co-référents
	############################################
	print "--------Union et numérotation des coreferents ----------------------\n";

	### départ de la fin et backtracking
	for (my $passes = 0 ; $passes < 3; $passes++){  
	
		#### pour toutes
		for ( my $u = 0 ; $u < $d; $u++) ### pour toutes les lignes
		{
		
			### offset de coréférence courant
			my $offco = $definition[$u][30];

			if ( $offco > -1  && $definition[$u][0] > 899 ) 
			{ 
				### la coref de l'index courant en partant le fin (par ex its => 219 ) est égal à celui de la coref précédente pointée par offco (par ex HK airport => 212) 
				$definition[$u][0] = $definition[$offco][0]; 
			}

		}
	}


	### Affichage témoins
	for ( my $u = 0 ; $u < $d; $u++) ### pour toutes les lignes
	{
		print "Document:$definition[$u][2]/ligne:$definition[$u][4] - Coref=$definition[$u][0]-$definition[$u][1]-$definition[$u][3]-$definition[$u][5]\]  \[$definition[$u][6]-$definition[$u][7]\]\n";
	}

	############################################
	### Renumérotation et identification des 
	### entités isolées
	############################################
	print "----- Renumérotation et identification des isolés -------------\n";
	my %hashrefcount = ();
	my %hashcorrespondances = ();
	my $coindexmax = 0; 
	
	### A ce stade, on à renumérotés tous les co-référents, prp comprises.
	### il reste quelques PRP isolées ou co-référentes

	
	### Élaboration de la nouvelle numérotation
	my $renum = 0; 
	$hashcorrespondances{1010} = 1010; ### à ne pas toucher

	for ( my $u = 0 ; $u < $d; $u++) ### pour toutes les lignes
	{
		if ( ! exists $hashcorrespondances{ $definition[$u][0] } )
		{
			$hashcorrespondances{ $definition[$u][0] } = $renum;
			$renum++;
		}
	}
	
	### Application de la nouvelle numérotation
	for ( my $u = 0 ; $u < $d; $u++) ### pour toutes les lignes
	{
		$definition[$u][0] = $hashcorrespondances{$definition[$u][0]} ;
	}


	### compte chaque ref	
	for ( my $u = 0 ; $u < $d; $u++) ### pour toutes les lignes
	{
		$hashrefcount{$definition[$u][0]}++;	
	}

	### Affichage témoins
	for ( my $u = 0 ; $u < $d; $u++) ### pour toutes les lignes
	{
		print "Document:$definition[$u][2]/ligne:$definition[$u][4] - Coref=$definition[$u][0]-$definition[$u][1]-$definition[$u][3]-$definition[$u][5]\]  \[$definition[$u][6]-$definition[$u][7]\]\n";
	}

	############################################
	### Segmentation par documents
	############################################
	
	## pour chaque doc
	for (my $doc = 0 ; $doc <= $docmax; $doc++)
	{	

		my %uniquedetecthash = (); ### la Hash pour compter les occurences locales 

		#print "----------------- Document $doc --------------------\n";
		## dans le tableau des corefs
		## Compter les occurences
		for (my $l = 0; $l < $d; $l++){

			## dans le doc
			if ( $definition[$l][2] == $doc )
			{
				if ( exists $uniquedetecthash{$definition[$l][0]} )
					{ 
						$uniquedetecthash{$definition[$l][0]}++; 
					} 
				else 	{ 
						$uniquedetecthash{$definition[$l][0]} = 1; 
					};

				#print "$uniquedetecthash{$definition[$l][0]}:Document:$definition[$l][2]/ligne:$definition[$l][4] - Coref=$definition[$l][0]-$definition[$l][1]\n";

			}
		}

		#print "\n";
		## dans le tableau des corefs
		## ne garder que ceux qui on plus de 1
		for (my $l = 0; $l < $d; $l++){

			## dans le doc
			if ( $definition[$l][2] == $doc )
			{
				### Si une seul occurence annuler
				if ( $uniquedetecthash{$definition[$l][0]} < 2 )
				{ 
					$definition[$l][0] = 9991; #### 9991 -> valeur rejetée localement
				}
				#print "$uniquedetecthash{$definition[$l][0]}:Document:$definition[$l][2]/ligne:$definition[$l][4] - Coref=$definition[$l][0]-$definition[$l][1]\n";
			
			}
		}
		#print "\n";
	}


	############################################
	###  
	### Sortie du fichier
	### 
	############################################


	############################################
	### Reconstruction du fichier avec 
	### ajout de corefs
	############################################

	my @mystockarchive = ();
	for (my $m = 0; $m < $c; $m++){ $mystockarchive[$m][0]=""; $mystockarchive[$m][1]=""; } ### met le tableau à 0:0 (début:fin)

	##### Identification des début:fin
	for (my $l = 0; $l < $d; $l++){

		### si référencé plus d'une fois 
		### Corrigé pour trier aussi les PRP 
		if ( $hashrefcount{$definition[$l][0]} > 1 && $definition[$l][0] < 900 ) {


			### chercher la fin
			### est à 1 si EN = 1 et >1 après ### ex : si à 1 => x + 1 - 1 sinon 
			my $beginindex = $definition[$l][4]; 
			my $nextindex = $definition[$l][4] + $definition[$l][8] - 1;

			#### remplit le tableau avec le num de coref
			$mystockarchive[$beginindex][0]=$mystockarchive[$beginindex][0] . $definition[$l][0] . ":"; 
			$mystockarchive[$nextindex][1]=$mystockarchive[$nextindex][1] . $definition[$l][0] . ":";

		}

	}

	############################################
	### Ressortir le doc 
	############################################
	open(sfile, ">$sortfile") || die "Impossible to sort\n"; 
	for (my $l = 0; $l < $c; $l++){

		### verbose
		# print "$stockage[$l][10]     $mystockarchive[$l][0]-$mystockarchive[$l][1]\n";

		# 73:29:
		#        29:
		## sortie
		# 12)|4)
		# (8|(1)
		$mystockarchive[$l][0] =~ s/:$//; ### retire le : de fin
		$mystockarchive[$l][1] =~ s/:$//; 
		@deb = split(/:/, $mystockarchive[$l][0]); ### splite le début
		@fin = split(/:/, $mystockarchive[$l][1]);  ### splite la fin
		
		### teste les cas
		my $adent = ""; # par défaut


		#### recherche les entités complètes
		$previous = 0;
		for (my $f = 0; $f < @deb; $f++){
			
			### Quand un numéro est aussi présent dans l'autre colonne
			### il faut fermer 
			for (my $g = 0; $g < @fin; $g++){
				if ( $deb[$f] == $fin[$g] && $deb[$f] >= 0 && $fin[$g]  >= 0 )
				{ 
					$adent = $adent . "($deb[$f])";
					### Remettre à 0  
					$deb[$f] = -1;
					$fin[$g] = -1;
					$previous = 1;
				}
			}
		}


		#### recherche les entités incomplètes fermées
		for (my $f = 0; $f < @fin; $f++){

			if ( $fin[$f] != -1 ) {
				if ( $previous == 1 ) { $adent = $adent . "|" ; }
				$adent = $adent . "$fin[$f])";
				$fin[$f] = -1 ;
				$previous = 1;
			}
		}


		#### recherche les entités incomplètes ouvertes
		for (my $f = 0; $f < @deb; $f++){

			if ( $deb[$f] != -1 ) {
				if ( $previous == 1 ) { $adent = $adent . "|" ; }
				$adent = $adent . "($deb[$f]";
				$deb[$f] = -1 ;
				$previous = 1;
			}
		}

		### si vide
		if ( ! $adent ) { $adent = "-"; }

		### Verbose
		#print "$stockage[$l][10]         $mystockarchive[$l][0] $mystockarchive[$l][1]\n"; 

		$stockage[$l][10] =~ s/\t/ /g; ### remplace les tab par des espaces 
		if ( $stockage[$l][10] =~ /[a-zA-Z]/ ) 
				{ 
					if ( $stockage[$l][10] =~ /^#/ ) {
						print sfile "$stockage[$l][10]\n";
					} else {
						print sfile "$stockage[$l][10] $adent\n"; 
					}
				} ### sort le fichier
		else { print sfile "\n"; }


	}
	close(sfile); 

}




#### Normalisation
sub normalize{
	my(@args) = @_;
	my $string = lc($args[0]); ### chaîne 1, minusculisée

	$string =~ s/\'s//g; ### retrait des apos s
	$string =~ s/[\+\-\_\)\(\[\]\.\"\'\`]/ /g; ### retrait des caractères bruitants
	$string =~ s/s$//g; ### s à la fin

	$string =~ s/\s+/ /g; ### espaces qui se suivent a 1
	$string =~ s/\s$//g; ### dernier espace toujours retiré

return($string);
}

#### compare deux chaines et retourne un % de mots identiques
sub substring{
	my(@args) = @_;
	my $string1 = lc($args[0]); ### chaîne 1
	my $string2 = lc($args[1]); ### chaîne 2
	my $substring = 0;
	

	########################################################
	# Retrait du marqueur de NP pour ne donner un poids
	# de comparaison que sur le lexique
	########################################################
	
	#### on ne prend pas le premier terme si (this, the etc)
	foreach $key ( keys %npdetect ){
		$string1 =~ s/^$key\s//;
		$string2 =~ s/^$key\s//;
	}
	#### on ne prend pas le premier terme si class NP complémentaire(its)
	foreach $key ( keys %npdetectbis ){
		$string1 =~ s/^$key\s//;
		$string2 =~ s/^$key\s//;
	}


	my @tabs1 = split(/\s/,$string1);
	my @tabs2 = split(/\s/,$string2);
		
	if ( $string1 eq $string2){ $substring = 1;} 
	
	## comparaisons
	my $match = 0;
	
	if ( @tabs1 == @tabs2 ){
		for ( my $a = 0; $a < @tabs1; $a ++){
			for ( my $b = 0; $b < @tabs2; $b ++){
				if ( $tabs1[$a] eq $tabs2[$b] ){
					$match++;
				}
			}
		}
		$max = @tabs1; 
	}
	if ( @tabs1 > @tabs2 ){
		for ( my $a = 0; $a < @tabs1; $a ++){
			for ( my $b = 0; $b < @tabs2; $b ++){
				if ( $tabs1[$a] eq $tabs2[$b] ){
					$match++;
				}
			}
		}
		$max = @tabs1; 
	} 

	if ( @tabs2 > @tabs1 ){
		for ( my $a = 0; $a < @tabs2; $a ++){
			for ( my $b = 0; $b < @tabs1; $b ++){
				if ( $tabs2[$a] eq $tabs1[$b] ){
					$match++;
				}
			}
		}
		$max = @tabs2;
	}
	
	if ($match > 0) { $substring = 1 / ( $max / $match ) ; }
	if ( $string1 eq $string2){ $substring = 1;} 

	$substring = sprintf("%0.2f", $substring);	

	#print "$string1:$string2:$max:$match    -$substring\n";

return($substring);
}

### Extraction de genre
### noun phrase [TAB]     Masculine_Count [SPACE] Feminine_Count [SPACE] Neutral_Count [SPACE] Plural_Count
sub gender{

	my(@args) = @_;
	my $gentag = $args[0]; ### le nom du user
	my @gtcount = split(/\s/, $gentag);

	$gentag ="U"; ### Undefined mode par défaut
	$genmode = "U"; ### Undefined plural
	
	if ($gtcount[0]>$gtcount[1] && $gtcount[0]>$gtcount[2]) { $gentag ="M";}
	if ($gtcount[1]>$gtcount[0] && $gtcount[1]>$gtcount[2]) { $gentag ="F";}
	if ($gtcount[2]>$gtcount[0] && $gtcount[2]>$gtcount[1]) { $gentag ="N";}

	## syrian journalists	0 0 0 1
	if ($gtcount[3]>0) { $genmode = "P"; } else { $genmode = "U"; } 

	#### renvoie GenreTemps UU US MS etc 
	my $genreturn = $gentag . $genmode; 

return($genreturn);
}

#### Récupérer le genre juste par le prénom
sub gendername{
	my(@args) = @_;
	my $name = $args[0]; ### le nom du user

	my @namesplit = split(/\s/, $name); 
	my $max = @namesplit; $max--; 
	## usuellement le premier est le prénom et le dernier le nom
	$namesplit[0] =~ s/\s//g;
	$namesplit[$max] =~ s/\s//g;


	my $genderreturn = "U"; #par défaut


	## Le premier -> martha wraith
	if ( exists $gender{$namesplit[0]} ){

		my $gtgender = $gender{$namesplit[0]}; ### collecte la ref
		my @gtcount = split(/\s/, $gtgender);

		if ($gtcount[0]>$gtcount[1] && $gtcount[0]>$gtcount[2]) { $genderreturn ="M";}
		if ($gtcount[1]>$gtcount[0] && $gtcount[1]>$gtcount[2]) { $genderreturn ="F";}	
	}

	#print "A[gendername:$name|$namesplit[0]|$namesplit[$max]|$genderreturn]\n";

	## Le dernier si pas trouvé avec le premier 
	## -> Document:0/ligne:86 - Coref=5-Palestinian leader Yasser Arafat -PERSON-JJ-G=U-Q=S 
	if ( $genderreturn eq "U" && exists $gender{$namesplit[$max]} ){
	
		my $gtgender = $gender{$namesplit[$max]}; ### collecte la ref
		my @gtcount = split(/\s/, $gtgender);
		
		if ($gtcount[0]>$gtcount[1] && $gtcount[0]>$gtcount[2]) { $genderreturn ="M";}
		if ($gtcount[1]>$gtcount[0] && $gtcount[1]>$gtcount[2]) { $genderreturn ="F";}	
	}

	#print "B[gendername:$name|$namesplit[0]|$namesplit[$max]|$genderreturn]\n";

return($genderreturn);
}

### Extraction de mode
### noun phrase [TAB] Masculine_Count [SPACE] Feminine_Count [SPACE] Neutral_Count [SPACE] Plural_Count
sub genderpron{

	my(@args) = @_;
	my $tgname = lc($args[0]); ### le texte

	my $gentag ="U"; ### genre Undefined par défaut
	my $temptag ="U"; ### temps Undefined par défaut

	### Vocabulaire
	$tgname =~ s/\'s $//; ## putin's
	$tgname =~ s/\s+$//; ### retire les \space à la fin	

	# $definition[$d][1]= $name; ### texte de coref
	# Mr , Ms, etc ... 
	if ( $tgname =~ /^mr|^sir/ ) { $gentag = "M"; $temptag = "S"; }
	if ( $tgname =~ /^ms|^mme/ ) { $gentag = "F"; $temptag = "S";}
	if ( $tgname =~ /^dr/ ) { $gentag = "U"; $temptag = "S";}
	
	#### PRP -
	#### Male Female Neutral Undefinite
	#### Singular Plural Undefinite
	if ( $tgname =~ /^i$|^me$|^you$|^i |^me |^you / ) { $temptag = "S"; $gentag= "U"; }
	if ( $tgname =~ /^he|^his|^him|^himself/ ) { $temptag = "S"; $gentag = "M"; }
	if ( $tgname =~ /^she|^her|^hers|^herself/ ) { $temptag = "S"; $gentag = "F"; }
	if ( $tgname =~ /^we|^us/ ) { $temptag = "P";$gentag = "U"; }
	if ( $tgname =~ /^our|^their|^they|^yours |^yours$|^them$|^them / ) { $temptag = "P"; $gentag = "U"; }
	if ( $tgname =~ /^it|^its|^itself/ ) { $temptag = "S"; $gentag = "N"; }

	### DT
	### Document:0/ligne:272 - Coref=15 - The owners of the boat --DT-G=U-Q=U
	if ( $tgname =~ /^the$|^this|^that|^a |^a$|^an |^an$|^another|^each|^one|^another/ ) { $temptag = "S"; $gentag = "U"; }
	if ( $tgname =~ /^these|^those|^any$|^some|^every|^all|^both|^either/ ) { $temptag= "P"; $gentag = "U"; }


	### ça se finit par un s
	## palestinians - NNPS
        ## the numbers
	if ($tgname =~ /[a-z]{3,20}s$/) { $temptag = "P"; }
	# il peut y avoir and : Russia and Japan 
	if ( $tgname =~ / and / ) { $temptag = "P"; }
	# Yesterday 's CNN / `` USA Today '' / Gallup tracking poll
	if ( $tgname =~ /[\/\&]/ ) { $temptag = "P"; }

	#### renvoie GenreTemps UU US MS etc 
	my $genreturn = $gentag . $temptag; 

return($genreturn);
}



