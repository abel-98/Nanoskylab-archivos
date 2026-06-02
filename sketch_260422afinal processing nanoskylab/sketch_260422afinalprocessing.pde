import processing.serial.*;
import java.awt.Desktop;
import java.net.URI;

Serial puerto;
String[] listaDatos;
boolean conectado = false;
PrintWriter archivoCSV, kml;

int maxPts = 60;
float[] hHum = new float[maxPts], hPres = new float[maxPts], hTemp = new float[maxPts], hAlt = new float[maxPts];

void setup() {
  size(1000, 850);
  try {
    if (Serial.list().length > 0) {
      puerto = new Serial(this, Serial.list()[0], 9600);
      puerto.bufferUntil('\n');
      conectado = true;
    }
  } catch (Exception e) { conectado = false; }
  
  archivoCSV = createWriter("data/telemetria.csv");
  archivoCSV.println("ID,Fecha,Hum,Pres,Temp,Lat,Lon,Alt");
}

void draw() {
  background(10, 15, 25);
  fill(30, 40, 60); noStroke(); rect(0, 0, width, 70);
  fill(255); textSize(24); textAlign(LEFT);
  text("NANOSKYLAB | GROUND CONTROL", 40, 42);
  
  if (listaDatos != null && listaDatos.length >= 8) {
    dibujarCaja(50, 100, "HUMEDAD RELATIVA", hHum, 0, 100, #00D2FF, "%");
    dibujarCaja(510, 100, "PRESIÓN ATMOSFÉRICA", hPres, 950, 1050, #FFCC00, " hPa");
    dibujarCaja(50, 320, "TEMPERATURA", hTemp, 0, 50, #FF6666, " °C");
    dibujarCaja(510, 320, "ALTITUD (MSL)", hAlt, -500, 3000, #99FF66, " m");
    
    fill(20, 45, 75); rect(50, 550, 900, 180, 10);
    fill(#FFCC00); textSize(45); 
    text("LAT: " + listaDatos[5] + "  LON: " + listaDatos[6], 80, 645);
    fill(255, 100); textSize(12);
    text("Sincronización KML activa: NanoSkyLab", 80, 705);
    
    if (frameCount % 60 < 30) { fill(255, 0, 0); ellipse(width - 50, 35, 12, 12); }
  } else {
    textAlign(CENTER); fill(255, 150); text("CONECTANDO CON NANOSKYLAB...", width/2, height/2);
  }
}

void serialEvent(Serial p) {
  String in = p.readStringUntil('\n');
  if (in != null) {
    in = trim(in);
    archivoCSV.println(in); archivoCSV.flush();
    String[] t = split(in, ',');
    if (t.length >= 8) {
      listaDatos = t;
      actualizar(hHum, float(t[2])); actualizar(hPres, float(t[3]));
      actualizar(hTemp, float(t[4])); actualizar(hAlt, float(t[7]));
      generarKML(t[5], t[6], t[7]); 
    }
  }
}

void generarKML(String lat, String lon, String alt) {
  kml = createWriter("data/posicion.kml");
  kml.println("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
  kml.println("<kml xmlns=\"http://www.opengis.net/kml/2.2\"><Placemark>");
  kml.println("<name>NanoSkyLab</name><Point>");
  kml.println("<altitudeMode>relativeToGround</altitudeMode>");
  kml.println("<coordinates>" + lon + "," + lat + "," + alt + "</coordinates>");
  kml.println("</Point></Placemark></kml>");
  kml.flush(); kml.close();
}

void dibujarCaja(int x, int y, String t, float[] d, float min, float max, color c, String u) {
  fill(15, 25, 40); stroke(255, 10); rect(x, y, 440, 200, 8);
  fill(200); textSize(14); text(t, x+20, y+30);
  fill(c); textSize(45); text(nf(d[d.length-1], 0, 1) + u, x+20, y+85);
  noFill(); stroke(c, 100); strokeWeight(2);
  beginShape();
  for(int i=0; i<d.length; i++) vertex(map(i,0,d.length-1,x+20,x+420), map(d[i],min,max,y+180,y+110));
  endShape();
}

void actualizar(float[] a, float v) {
  for(int i=0; i<a.length-1; i++) a[i] = a[i+1];
  a[a.length-1] = v;
}

void exit() { archivoCSV.flush(); archivoCSV.close(); super.exit(); }
