/**
* Name: Modele1
* Author: Madaliou
* Description: Simulation d'un parking(approche 1)
* 
*/

model Modele1

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
		
	  
		int tense <- 500;
	    int intensity <- 2;
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

         reflex NewCar when: every (tense/intensity){ 
         create car number:1 {
         location <- any_location_in(one_of(depart));
         target <- any_location_in(one_of(entree));
         aim <- "Enter";
            }
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
	
	state Free initial:true{
	}
	
	state Taken{
	}
	
}

species car skills:[moving]{
	 rgb color init: #red;//type color, variable color,initialisation
     int size init:8 + rnd(2);
     float speed init:  0.3;
     string aim <- nil;
     point target <- nil;
     place goal <- nil;
     int pauseTime <- 800 + rnd(1000);
     int amount <- 0;
     int count <- 0;
     int parkingSize <- 0;  
     
     aspect base{
     	draw circle(size) color:color;
     	}
     	
     	
     	reflex goEnter when: aim="Enter" and target!=nil{
     		do goto target:target on:route1 speed:speed;
     		if(self.location=target){
     			target <- nil;	
     		list neighbour <- list(place) where (each.state="Free" );
     		list neighbour1 <- list(place) where (each.type="large" and each.state="Free");
     		list neighbour2 <- list(place) where ((each.type="medium" or each.type="large") and each.state="Free");
     		
     		switch self.size {
						match 8 {
								if(length(neighbour) > 0){
	     			            goal <- first(neighbour);
	     			            aim <- "Park";
	     			            if(goal.type="large"){
	     			            	parkingSize <- 11;
	     			            }else if(goal.type="medium"){
	     			            	parkingSize<-10;
	     			            }else {
	     			            	parkingSize <- 9;
	     			            }
	     			            ask goal {
	     				        set state <- "Taken";
	     			                }
							    }else {
	     			               target <- any_location_in(one_of(arrive));
	     			               aim <- "retour";
	     		            	}
     		            }
						match 9 {
									if(length(neighbour2) > 0){
		     			            goal <- first(neighbour2);
		     			            aim <- "Park";
		     			            if(goal.type="large"){
		     			            	parkingSize <- 11;
		     			            }else {
		     			            	parkingSize <- 10;
		     			            }
		     			            ask goal {
		     				        set state <- "Taken";
		     			            }
								     }else {
		     			                    target <- any_location_in(one_of(arrive));
		     			                    aim <- "retour";
		     		            	 }
						}
						match 10 {
									if(length(neighbour1) > 0){
		     			            goal <- first(neighbour1);
		     			            aim <- "Park";
		     			            parkingSize <- 11;
		     			            ask goal {
		     				        set state <- "Taken";
		     			            }
								    }else {
		     			                   target <- any_location_in(one_of(arrive));
		     			                   aim <- "retour";
		     		            	}
						}
						default {write "Erreur"; }
						}
     		}
     		
     	}
     	
     	reflex Park when:goal!=nil and aim="Park"{
     		do goto target:goal on:route1 speed:speed;
     		count <- count+1;
     		if(count > pauseTime){
     			aim <- "sortir";
     			target <- any_location_in(one_of(sortie));
     			ask goal {
     				set state <- "Free";
     			}
     			goal <- nil;
     		}
     	}
     	
     reflex Sortir when:target!=nil and aim="sortir"{
     	do goto target:target on:route1 speed:speed;
     	if(self.location=target){
     		target <- nil;
     		aim <-"partir";
     		amount <- parkingSize * pauseTime;
     		if (amount!=0){
     			target <- any_location_in(one_of(arrive));
     		}
     	}
     }
     
     reflex Sortir_Parking when:target!=nil and aim="partir"{
     	do goto target:target speed:speed;
     	if(self.location=target){
     		do die;
     	}
     }
     
     reflex Retour when:target!=nil and aim="retour"{
     	do goto target:target speed:speed;
     	if(self.location=target){
     		do die;
     	}
     }
     	 
}


experiment Modele1 type: gui {
	
	parameter "Intensite" var: intensity  category: "car" ;
	output {
		display parking_display type:opengl{
			species car aspect:base;
			species place aspect: base ;
			species route aspect: base ;
			species depart aspect: base ;
			species arrive aspect: base ;
			species entree aspect: base ;
			species sortie aspect: base ;
		}
	}
}