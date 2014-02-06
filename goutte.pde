/* Visuel pour une goutte détectée */

/* Couleurs */
color[] listeCouleurs = {
  color(232,243,248,200),
  color(219,230,236,200),
  color(194,203,206,200),
  color(164,188,194,200),
  color(129,168,184,200)
};

class Goutte{
  
  float diametre;
  float opacite;
  float x;
  float y;
  color couleur;
  float coefTaille = 4;
  
  Goutte(int _intensite){
    this.init(_intensite);
  }
  
  void render(){
    stroke(255, 255, 255, 20);
    strokeWeight(8);
    fill(this.couleur);
    ellipse(this.x, this.y, this.diametre, this.diametre);
  }
  
  void init(int _intensite){
    this.diametre = (width / _intensite) * (width / coefTaille);
    this.x = int(random(0, width));
    this.y = int(random(0, height));
    this.couleur = listeCouleurs[int(random(listeCouleurs.length))];
  }
}
