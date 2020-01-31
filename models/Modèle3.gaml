/**
* Name: Modele3
* Author: Bandissougle
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model Modele3

/* Insert your model definition here */

global{
		file place_shapefile <- file("../includes/Place.shp");
		file arrive_shapefile <- file("../includes/Arrivee.shp");
		file depart_shapefile <- file("../includes/Depart.shp");
		file entre_shapefile <- file("../includes/Entree.shp");
		file route1_shapefile <- file("../includes/Route1.shp");
		file route2_shapefile <- file("../includes/Route2.shp");
		file sortie_shapefile <- file("../includes/Sortie.shp");
		file limites_shapefile <- file("../includes/Limites.shp");
		
	    
	    int place_dispo <- 0;
	    int place_dispo_to <- 0;
		int temps <- 500;
		int revenu <- 0;
		int montant_total <- 0;
		float heure <- 3600 #s;
	    int intensite <- 2;
		graph route1;
		graph route2;
		geometry shape <- envelope(limites_shapefile);
		
		
		init{
			create depart from: depart_shapefile ;
			create arrive from: arrive_shapefile ;
			create entree from: entre_shapefile ;
			create sortie from: sortie_shapefile ;
			create route from: route1_shapefile ;
            route1 <- as_edge_graph(route);
            create route from: route2_shapefile;
            route2 <- as_edge_graph(route); 
		    create place from: place_shapefile with: [type::string(read ("Taille"))] {
            }
            
         }

         reflex NewVoiture when: every (temps/intensite){ 
         create voiture number:1 {
         location <- any_location_in(one_of(depart));
         target <- any_location_in(one_of(entree));
         objectif <- "Entrer";
            }
         }
         reflex caclul when:every(heure){
         	revenu <- montant_total;
         	place_dispo_to <- place_dispo_to+ place_dispo;
         	montant_total <- 0;
         	
         }
}
species route  {
	rgb color <- #red ;
	aspect base {
		draw shape color: color ;
	}
}

species depart {
	aspect base{
		draw shape color:color;
	}
}

species arrive {
	aspect base{
		draw shape color:color;
	}
}

species entree {
	aspect base{
		draw shape color:color;
	}
}

species sortie{
	aspect base{
		draw shape color:color;
	}
}


species place control:fsm{
	string type; 
	rgb color <- #gray  ;
	
	
	aspect base {
		draw shape color: color ;
	}
	
	state Libre initial:true{
	}
	
	state Occuper{
	}
	
}

species voiture skills:[moving]{
	 rgb color init: #red;//type color, variable color,initialisation
     int size init:8 + rnd(2);
     float speed init:  0.3;
     string objectif <- nil;
     point target <- nil;
     place but <- nil;
     int temps_pause <- 800 + rnd(1000);
     int montant <- 0;
     int count <- 0;
     int taille_parking <- 0;
     
     
     
     aspect base{
     	draw circle(size) color:color;
     	}
     	
     	
     	reflex Aller_entrer when: objectif="Entrer" and target!=nil{
     		do goto target:target on:route1 speed:speed;
     		if(self.location=target){
     			target <- nil;	
     		list voisin <- list(place) where (each.state="Libre" and each.type="petit" );
     		list voisin1 <- list(place) where (each.type="grand" and each.state="Libre");
     		list voisin2 <- list(place) where (each.type="moyen" and each.state="Libre");
     		
     		switch self.size {
						match 8 {
								if(length(voisin) > 0){
	     			            but <- first(voisin);
	     			            objectif <- "Garer";
	     			            taille_parking <- 9;
	     			            ask but {
	     				        set state <- "Occuper";
	     			                }
							    }else {
	     			               target <- any_location_in(one_of(arrive));
	     			               objectif <- "retour";
	     		            	}
     		            }
						match 9 {
									if(length(voisin2) > 0){
		     			            but <- first(voisin2);
		     			            objectif <- "Garer";
		     			            taille_parking <- 10;
		     			            ask but {
		     				        set state <- "Occuper";
		     			            }
								     }else {
		     			                    target <- any_location_in(one_of(arrive));
		     			                    objectif <- "retour";
		     		            	 }
						}
						match 10 {
									if(length(voisin1) > 0){
		     			            but <- first(voisin1);
		     			            objectif <- "Garer";
		     			            taille_parking <- 11;
		     			            ask but {
		     				        set state <- "Occuper";
		     			            }
								    }else {
		     			                   target <- any_location_in(one_of(arrive));
		     			                   objectif <- "retour";
		     		            	}
						}
						default {write "Erreur"; }
						}
     		}
     		
     	}
     	
     	reflex Garer when:but!=nil and objectif="Garer"{
     		do goto target:but on:route1 speed:speed;
     		count <- count+1;
     		if(count > temps_pause){
     			objectif <- "sortir";
     			target <- any_location_in(one_of(sortie));
     			ask but {
     				set state <- "Libre";
     			}
     			but <- nil;
     		}
     	}
     	
     reflex Sortir when:target!=nil and objectif="sortir"{
     	do goto target:target on:route1 speed:speed;
     	if(self.location=target){
     		target <- nil;
     		objectif <-"partir";
     		montant <- taille_parking * temps_pause;
     		montant_total <- montant_total+montant;
     		list voisin <- list(place) where (each.state="Libre" );
     		place_dispo <- length(voisin);
     		if (montant!=0){
     			target <- any_location_in(one_of(arrive));
     		}
     	}
     }
     
     reflex Sortir_Parking when:target!=nil and objectif="partir"{
     	do goto target:target speed:speed;
     	if(self.location=target){
     		do die;
     	}
     }
     
     reflex Retour when:target!=nil and objectif="retour"{
     	do goto target:target speed:speed;
     	if(self.location=target){
     		do die;
     	}
     }
     	 
}


experiment Modele3 type: gui {
	
	parameter "Intensite" var: intensite  category: "voiture" ;
	output {
		display parking_display type:opengl{
			species voiture aspect:base;
			species place aspect: base ;
			species route aspect: base ;
			species depart aspect: base ;
			species arrive aspect: base ;
			species entree aspect: base ;
			species sortie aspect: base ;
		}
		
		display My_chart refresh:every(3600#s){
         chart "diagram" type:series size: {1, 0.5} position: {0, 0}{
             data "revenu_par_heure" value:revenu style: line color: #green ;
             data "place_dispo_par_heure" value:place_dispo_to style: line color: #red ;
   
	        }        
         }
     }
}