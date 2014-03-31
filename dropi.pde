/*---------------------------------------------------------------- LIBRAIRIES */
import org.puredata.processing.PureData;
import processing.serial.*;
import cc.arduino.*;

/*---------------------------------------------------------------- OBJETS */
PureData pd;
Arduino arduino;

/*---------------------------------------------------------------- VARIABLES */

/* Note : plus il y a d'eau, plus la valeur est petite, moins il y en a, plus la valeur est grande. */

/* Paramètres Processing */
int pinReadNote     = 0;                        // Pin Analog connectée pour donner l'info de la note
int pinReadDecay    = 9;                        // Pin Analog connectée pour donner l'info de Decay
int seuil           = 900;                      // Seuil en dessous duquel on commence à détecter
int tolerance       = 20;                       // Tolérance sur le changement de valeurs (20 est pas mal)
String nomPatch     = "dropi.pd";               // Nom du patch Pure Data
String portArduino;                             // Port sur lequel est connecté l'arduino
float velocite      = 4;                        // Rapidité de disparition des gouttes d'eau (visuel)
int pinValeurMax    = 1023;                     // Valeur Max que l'input peut retourner

/* Paramètres Pure Data */
float tremoloMax    = 7;                        // Oscillation tremolo Maximum
float attackMax     = 1000;                     // Attack du filtre Maximum
float releaseMax    = 1500;                     // Release du filtre Maximum
                 
/* Variables */
int intensiteNote;
int old_intensiteNote;
int valueDecay;
int old_valueDecay;
int noteCle;
int noteGeneree;
int octaveGeneree;
int nbOscillateurs;
int[] scale;
ArrayList<Goutte> gouttes;
int placeTrouve;

float tremolo;
float attack;
float release;

/*---------------------------------------------------------------- SETUP */
void setup() {
  size(displayWidth, displayHeight);
  smooth();
  
  /* Ouverture et démarrage du patch Pure Data */
  pd = new PureData(this, 44100, 0, 2);
  pd.openPatch(nomPatch);
  pd.start();
  
  /* Déclaration de l'arduino */
  portArduino = Arduino.list()[0];
  arduino = new Arduino(this, portArduino, 57600);
  
  /* Déclaration des pins utilisées dans l'Arduino */
  arduino.pinMode(pinReadNote, Arduino.INPUT);
  arduino.pinMode(pinReadDecay, Arduino.INPUT);
  
  scale = minor;
  noteCle = C3;
  noteGeneree = noteCle;
  gouttes = new ArrayList<Goutte>();
}

/*---------------------------------------------------------------- LOOP */
void draw() {
  background(231, 231, 223);
  
  getValeurs();
 
  if (toleranceNote() == true){
    setNote();
    playNote();
    
    ajouteGoutte();
  }
  
  afficheGouttes();
}

/*---------------------------------------------------------------- FONCTIONS */

void setNote(){
  // Note
  noteGeneree = int(random(scale.length));
  octaveGeneree = int(random(octaves.length));
  noteGeneree = noteCle + scale[noteGeneree] + octaves[octaveGeneree];
  
  // Tremolo : prend en compte l'intensité
  tremolo = intensiteNote * tremoloMax / pinValeurMax;
  
  // Attack du filtre
  attack = intensiteNote * attackMax / pinValeurMax;
  
  //Release du filtre
  release = intensiteNote * releaseMax / pinValeurMax;
}

void playNote(){
  nbOscillateurs++;
  if(nbOscillateurs == 5){
    nbOscillateurs = 1;
  }
  
  /* Oscillateurs de 1 à 4 */
  pd.sendFloat("tremolo" + nbOscillateurs, tremolo);
  pd.sendFloat("attack" + nbOscillateurs, attack);
  pd.sendFloat("release" + nbOscillateurs, release);
  pd.sendFloat("note" + nbOscillateurs, noteGeneree);
  pd.sendBang("banger" + nbOscillateurs);
  
  /* Oscillateur 5 qui joue tout le temps */
  pd.sendFloat("tremolo", tremolo);
  pd.sendFloat("attack", attack);
  pd.sendFloat("release", release);
  pd.sendFloat("note", noteGeneree);
  pd.sendBang("banger");
}

/* Lis les valeurs de l'Arduino */
void getValeurs(){
  intensiteNote = arduino.analogRead(pinReadNote);
  if(intensiteNote == 0){
    intensiteNote = 1;
  }
}

/* Test si la variation est assez importante pour la prendre en compte */
boolean toleranceNote(){
  // Si on est en dessous du seuil
  if(intensiteNote < seuil){
    // Si la variation entre la valeur actuelle et la dernière valeur retenue 
    // est supérieure ou inférieure à la tolérance
    if((intensiteNote >= old_intensiteNote + tolerance) || (intensiteNote < old_intensiteNote - tolerance)){
      old_intensiteNote = intensiteNote;
      //delay(1000);
      return true;
    }else{
      return false;
    }
  }else{
    return false;
  }
}

void ajouteGoutte(){
  /* 
  L'idée est de chercher une goutte qui a fini de rétrécir, et on la réinitialise. 
  Ca évite de rajouter trop de gouttes dans l'array d'objets. Si on ne trouve pas de place libre, 
  alors on en ajoute une.
  */
  
  // On n'a pas encore trouvé de place libre
  placeTrouve = 0;
  for(int i=0; i<gouttes.size(); i++){
    if(gouttes.get(i).diametre <= 0 && placeTrouve == 0){
      gouttes.get(i).init(intensiteNote);
      placeTrouve = 1;
    }
  }
  if(placeTrouve == 0){
    gouttes.add(new Goutte(intensiteNote));
  }
}

void afficheGouttes(){
  /*
  On rétrécit le diametre de chaque goutte en loop
  */
  for(int i=0; i<gouttes.size(); i++){
    gouttes.get(i).render();
    if(gouttes.get(i).diametre > 0){
      gouttes.get(i).diametre = gouttes.get(i).diametre - velocite;
    }else{
      // Cette condition else sert à "arrondir" à 0 quand on a des valeurs négatives. 
      gouttes.get(i).diametre = 0;
    }
  }
}

boolean sketchFullScreen() {
  return true;
}
