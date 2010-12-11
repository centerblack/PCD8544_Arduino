/* PCD8544, 84x48 Pixel LCD
 * http://www.sparkfun.com/products/10168

 * This code expands upon what I found here
 * http://www.arduino.cc/playground/Code/PCD8544
 * http://www.arduino.cc/playground/Code/PrintFloats
 
 * The main addition is setPixel(), which lets you set pixels
 * on/off at a specific x,y coordinate.
*/

#include <stdlib.h>
#define PIN_SCE   7  // LCD CS  .... Pin 3
#define PIN_RESET 6  // LCD RST .... Pin 1
#define PIN_DC    5  // LCD Dat/Com. Pin 5
#define PIN_SDIN  4  // LCD SPIDat . Pin 6
#define PIN_SCLK  3  // LCD SPIClk . Pin 4
// LCD Gnd .... Pin 2
// LCD Vcc .... Pin 8
// LCD Vlcd ... Pin 7

#define LCD_C     LOW
#define LCD_D     HIGH

#define LCD_X     84
#define LCD_Y     48
#define LCD_CMD   0

void LcdWrite(byte dc, byte data);
void LcdCharacter(char character);
void LcdClear(void);
void LcdInitialise(void);
void LcdString(char *characters);

void LcdInteger(int num);
void LcdFloat(float num, int precision=3);
void gotoXY(int x, int y);
void drawBars(int bars);
char * floatToString(char * outstr, float value, int places, int minwidth=0, bool rightjustify=false);
void setup(void);

int progress = 0;
int prev_prog = 0;
int pixels[85][6] = {{0}};

// Data to draw a map of the world
static const byte WORLDMAP[][5] =
{
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x80, 0x00, 0x60},
{0xC0, 0xF0, 0xDC, 0x7C, 0X3C},
{0x1C, 0xF0, 0xF8, 0xF0, 0xF0},
{0xF8, 0xF8, 0xFE, 0xFE, 0xE6},
{0xD4, 0x00, 0x10, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x80, 0x80},
{0x40, 0x00, 0x00, 0x00, 0x00},
{0x20, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x60, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00}, // ROW 1 END

{0x00, 0x00, 0x00, 0x00, 0x80},
{0x80, 0x80, 0x80, 0x80, 0x80},
{0x00, 0x00, 0x00, 0xB0, 0x70},
{0xC0, 0x60, 0x00, 0xB0, 0x90},
{0x28, 0xE3, 0x41, 0xC0, 0x81},
{0x01, 0x03, 0x0F, 0x3F, 0xFF},
{0xFF, 0xFF, 0xFF, 0xBF, 0x0F},
{0x02, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x81, 0x81},
{0x80, 0x80, 0x00, 0x00, 0x00},
{0x00, 0x70, 0x08, 0x84, 0x40},
{0x00, 0xE0, 0x80, 0xF0, 0xF8},
{0xF8, 0xFC, 0xFC, 0xEC, 0xE0},
{0xE0, 0xE0, 0xE0, 0xC0, 0xC0},
{0xE0, 0xC0, 0xC0, 0x80, 0x00},
{0x80, 0x00, 0x80, 0x00, 0x00}, // ROW 2 END

{0x00, 0x00, 0x00, 0x00, 0x0B},
{0x3F, 0x0F, 0x0F, 0x0F, 0x0F},
{0x1F, 0x3F, 0xFF, 0xFF, 0xFF},
{0xFE, 0xFF, 0xFE, 0xFE, 0xE7},
{0xC1, 0xC1, 0x00, 0xF8, 0xF7},
{0xE5, 0xC0, 0x00, 0x03, 0x0F},
{0x07, 0x01, 0x00, 0x00, 0x00},
{0x06, 0x00, 0x00, 0x00, 0x80},
{0x00, 0x98, 0xBC, 0xD7, 0xE9},
{0xEF, 0xFF, 0xFD, 0xFC, 0xFE},
{0xFF, 0xFF, 0xFF, 0xFF, 0xFF},
{0xFE, 0xFE, 0xFF, 0xFF, 0xFF},
{0xFF, 0xFF, 0xFF, 0xFF, 0xFF},
{0xFF, 0xFF, 0xFF, 0xFF, 0xBF},
{0x0F, 0x0F, 0x0F, 0x0F, 0x3F},
{0x0F, 0x0F, 0x07, 0x03, 0x02}, // ROW 3 END

{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x0F, 0x1F},
{0x3F, 0x7F, 0xFF, 0x7F, 0x3F},
{0x3E, 0x3D, 0x1B, 0x07, 0x03},
{0x01, 0x00, 0x01, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x80, 0xC0, 0xEC, 0xED},
{0xF3, 0xF3, 0xE5, 0xC3, 0xEF},
{0xE7, 0xE9, 0x29, 0xFB, 0xFF},
{0xB1, 0xBD, 0x7F, 0x7F, 0x7F},
{0xFF, 0xFF, 0xFF, 0xFF, 0x7F},
{0xFF, 0xFF, 0xFF, 0xFF, 0x7F},
{0x67, 0x07, 0x07, 0x13, 0x01},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00}, // ROW 4 END

{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x01, 0x00},
{0x03, 0x02, 0x30, 0xFC, 0xFC},
{0xFC, 0xF8, 0xF8, 0xE0, 0xE0},
{0xE0, 0x40, 0x00, 0x00, 0x00},
{0x00, 0x03, 0x07, 0x07, 0x07},
{0x07, 0x07, 0xBF, 0xFF, 0xFF},
{0xFF, 0xFF, 0xFF, 0x1E, 0x0F},
{0x05, 0x01, 0x00, 0x00, 0x00},
{0x00, 0x07, 0x01, 0x00, 0x00},
{0x01, 0x11, 0x23, 0x10, 0x10},
{0x00, 0x00, 0x00, 0x80, 0x20},
{0xA0, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00}, // ROW 5 END

{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0xFC},
{0x7F, 0x3F, 0x0F, 0x0F, 0x03},
{0x01, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x01, 0x07, 0x0F},
{0x0F, 0x07, 0x00, 0x00, 0x03},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x00},
{0x00, 0x00, 0x00, 0x00, 0x06},
{0x0E, 0x0F, 0x0F, 0x0F, 0x0F},
{0x1F, 0x5E, 0x0C, 0x00, 0x00},
{0x00, 0x80, 0x00, 0x00, 0x00}, // ROW 6 END
};

static const byte ASCII[][5] =
{
{0x00, 0x00, 0x00, 0x00, 0x00} // 20  
,{0x00, 0x00, 0x5f, 0x00, 0x00} // 21 !
,{0x00, 0x07, 0x00, 0x07, 0x00} // 22 "
,{0x14, 0x7f, 0x14, 0x7f, 0x14} // 23 #
,{0x24, 0x2a, 0x7f, 0x2a, 0x12} // 24 $
,{0x23, 0x13, 0x08, 0x64, 0x62} // 25 %
,{0x36, 0x49, 0x55, 0x22, 0x50} // 26 &
,{0x00, 0x05, 0x03, 0x00, 0x00} // 27 '
,{0x00, 0x1c, 0x22, 0x41, 0x00} // 28 (
,{0x00, 0x41, 0x22, 0x1c, 0x00} // 29 )
,{0x14, 0x08, 0x3e, 0x08, 0x14} // 2a *
,{0x08, 0x08, 0x3e, 0x08, 0x08} // 2b +
,{0x00, 0x50, 0x30, 0x00, 0x00} // 2c ,
,{0x08, 0x08, 0x08, 0x08, 0x08} // 2d -
,{0x00, 0x60, 0x60, 0x00, 0x00} // 2e .
,{0x20, 0x10, 0x08, 0x04, 0x02} // 2f /
,{0x3e, 0x51, 0x49, 0x45, 0x3e} // 30 0
,{0x00, 0x42, 0x7f, 0x40, 0x00} // 31 1
,{0x42, 0x61, 0x51, 0x49, 0x46} // 32 2
,{0x21, 0x41, 0x45, 0x4b, 0x31} // 33 3
,{0x18, 0x14, 0x12, 0x7f, 0x10} // 34 4
,{0x27, 0x45, 0x45, 0x45, 0x39} // 35 5
,{0x3c, 0x4a, 0x49, 0x49, 0x30} // 36 6
,{0x01, 0x71, 0x09, 0x05, 0x03} // 37 7
,{0x36, 0x49, 0x49, 0x49, 0x36} // 38 8
,{0x06, 0x49, 0x49, 0x29, 0x1e} // 39 9
,{0x00, 0x36, 0x36, 0x00, 0x00} // 3a :
,{0x00, 0x56, 0x36, 0x00, 0x00} // 3b ;
,{0x08, 0x14, 0x22, 0x41, 0x00} // 3c <
,{0x14, 0x14, 0x14, 0x14, 0x14} // 3d =
,{0x00, 0x41, 0x22, 0x14, 0x08} // 3e >
,{0x02, 0x01, 0x51, 0x09, 0x06} // 3f ?
,{0x32, 0x49, 0x79, 0x41, 0x3e} // 40 @
,{0x7e, 0x11, 0x11, 0x11, 0x7e} // 41 A
,{0x7f, 0x49, 0x49, 0x49, 0x36} // 42 B
,{0x3e, 0x41, 0x41, 0x41, 0x22} // 43 C
,{0x7f, 0x41, 0x41, 0x22, 0x1c} // 44 D
,{0x7f, 0x49, 0x49, 0x49, 0x41} // 45 E
,{0x7f, 0x09, 0x09, 0x09, 0x01} // 46 F
,{0x3e, 0x41, 0x49, 0x49, 0x7a} // 47 G
,{0x7f, 0x08, 0x08, 0x08, 0x7f} // 48 H
,{0x00, 0x41, 0x7f, 0x41, 0x00} // 49 I
,{0x20, 0x40, 0x41, 0x3f, 0x01} // 4a J
,{0x7f, 0x08, 0x14, 0x22, 0x41} // 4b K
,{0x7f, 0x40, 0x40, 0x40, 0x40} // 4c L
,{0x7f, 0x02, 0x0c, 0x02, 0x7f} // 4d M
,{0x7f, 0x04, 0x08, 0x10, 0x7f} // 4e N
,{0x3e, 0x41, 0x41, 0x41, 0x3e} // 4f O
,{0x7f, 0x09, 0x09, 0x09, 0x06} // 50 P
,{0x3e, 0x41, 0x51, 0x21, 0x5e} // 51 Q
,{0x7f, 0x09, 0x19, 0x29, 0x46} // 52 R
,{0x46, 0x49, 0x49, 0x49, 0x31} // 53 S
,{0x01, 0x01, 0x7f, 0x01, 0x01} // 54 T
,{0x3f, 0x40, 0x40, 0x40, 0x3f} // 55 U
,{0x1f, 0x20, 0x40, 0x20, 0x1f} // 56 V
,{0x3f, 0x40, 0x38, 0x40, 0x3f} // 57 W
,{0x63, 0x14, 0x08, 0x14, 0x63} // 58 X
,{0x07, 0x08, 0x70, 0x08, 0x07} // 59 Y
,{0x61, 0x51, 0x49, 0x45, 0x43} // 5a Z
,{0x00, 0x7f, 0x41, 0x41, 0x00} // 5b [
,{0x02, 0x04, 0x08, 0x10, 0x20} // 5c ¥
,{0x00, 0x41, 0x41, 0x7f, 0x00} // 5d ]
,{0x04, 0x02, 0x01, 0x02, 0x04} // 5e ^
,{0x40, 0x40, 0x40, 0x40, 0x40} // 5f _
,{0x00, 0x01, 0x02, 0x04, 0x00} // 60 `
,{0x20, 0x54, 0x54, 0x54, 0x78} // 61 a
,{0x7f, 0x48, 0x44, 0x44, 0x38} // 62 b
,{0x38, 0x44, 0x44, 0x44, 0x20} // 63 c
,{0x38, 0x44, 0x44, 0x48, 0x7f} // 64 d
,{0x38, 0x54, 0x54, 0x54, 0x18} // 65 e
,{0x08, 0x7e, 0x09, 0x01, 0x02} // 66 f
,{0x0c, 0x52, 0x52, 0x52, 0x3e} // 67 g
,{0x7f, 0x08, 0x04, 0x04, 0x78} // 68 h
,{0x00, 0x44, 0x7d, 0x40, 0x00} // 69 i
,{0x20, 0x40, 0x44, 0x3d, 0x00} // 6a j 
,{0x7f, 0x10, 0x28, 0x44, 0x00} // 6b k
,{0x00, 0x41, 0x7f, 0x40, 0x00} // 6c l
,{0x7c, 0x04, 0x18, 0x04, 0x78} // 6d m
,{0x7c, 0x08, 0x04, 0x04, 0x78} // 6e n
,{0x38, 0x44, 0x44, 0x44, 0x38} // 6f o
,{0x7c, 0x14, 0x14, 0x14, 0x08} // 70 p
,{0x08, 0x14, 0x14, 0x18, 0x7c} // 71 q
,{0x7c, 0x08, 0x04, 0x04, 0x08} // 72 r
,{0x48, 0x54, 0x54, 0x54, 0x20} // 73 s
,{0x04, 0x3f, 0x44, 0x40, 0x20} // 74 t
,{0x3c, 0x40, 0x40, 0x20, 0x7c} // 75 u
,{0x1c, 0x20, 0x40, 0x20, 0x1c} // 76 v
,{0x3c, 0x40, 0x30, 0x40, 0x3c} // 77 w
,{0x44, 0x28, 0x10, 0x28, 0x44} // 78 x
,{0x0c, 0x50, 0x50, 0x50, 0x3c} // 79 y
,{0x44, 0x64, 0x54, 0x4c, 0x44} // 7a z
,{0x00, 0x08, 0x36, 0x41, 0x00} // 7b {
,{0x00, 0x00, 0x7f, 0x00, 0x00} // 7c |
,{0x00, 0x41, 0x36, 0x08, 0x00} // 7d }
,{0x10, 0x08, 0x08, 0x10, 0x08} // 7e ←
,{0x00, 0x06, 0x09, 0x09, 0x06} // 7f →
};

void setup(void) {
  Serial.begin(9600);
  LcdInitialise();
  
  initProgressBar();
    while (progress < 100) {
  progress++;
  
  //if (progress > 100) progress = 0;
  
  setProgressBar(progress);
  delay(25);
  }
  LcdClear();
  clearPixels();
  
  drawWorldMap();
  drawHorizontalLine(0,0,84);
  drawHorizontalLine(0,47,84);
  drawVerticalLine(0,0,48);
  drawVerticalLine(83,0,48);
  
}

void loop(void) {

}

void drawWorldMap() {
  for (int row = 0; row < 6; row++) {
    gotoXY(0,row);
    for (int chr = 0; chr < 16; chr++) {
      for (int index = 0; index < 5; index++) {
        LcdWrite(LCD_D, WORLDMAP[(row*16)+chr][index]);
        pixels[index+chr*5][row] = WORLDMAP[(row*16)+chr][index];
      }
    }
    
  }
}

void initProgressBar() {
  LcdClear();
  clearPixels();
  drawRect(10,21, 64, 5);
}

void setProgressBar(int value) {
  int startValue = ((float)prev_prog/100.0)*64;
  int newValue = ((float)value/100.0)*64;
  if (newValue < startValue) { startValue = 0; }
    
  int pb_x = 10;
  int pb_y = 21;
  for (int i=startValue;i<newValue;i++)
  {
    drawVerticalLine(pb_x+i,pb_y,5);
  }
  prev_prog = value;
}

void drawMac(int x, int y){
  drawHorizontalLineXY(2+x,		23+x,	0+y);
  drawHorizontalLineXY(4+x,		21+x,	3+y);
  drawHorizontalLineXY(12+x,	13+x,	11+y);
  drawHorizontalLineXY(11+x,	14+x,	14+y);
  drawHorizontalLineXY(4+x,		21+x,	17+y);
  drawHorizontalLineXY(3+x,		5+x,	22+y);
  drawHorizontalLineXY(15+x,	21+x,	22+y);
  drawHorizontalLineXY(1+x,		24+x,	27+y);
  drawHorizontalLineXY(2+x,		23+x,	31+y);
  
  drawVerticalLineXY(2+y,		26+y,	0+x);
  drawVerticalLineXY(1+y,		1+y,	1+x);
  drawVerticalLineXY(28+y,		30+y,	1+x);
  drawVerticalLineXY(4+y,		16+y,	3+x);
  drawVerticalLineXY(7+y,		8+y,	9+x);
  drawVerticalLineXY(13+y,		13+y,	10+x);
  drawVerticalLineXY(7+y,		11+y,	13+x);
  drawVerticalLineXY(7+y,		8+y,	17+x);
  drawVerticalLineXY(13+y,		13+y,	15+x);
  drawVerticalLineXY(4+y,		16+y,	22+x);
  drawVerticalLineXY(1+y,		1+y,	24+x);
  drawVerticalLineXY(28+y,		30+y,	24+x);
  drawVerticalLineXY(2+y,		26+y,	25+x);
}

void clearPixels() {
  for (int x=0;x<83;x++) {
    for(int y=0;y<47;y++) {
      pixels[x][y] = 0;
    }
  }
}

// Enable or disable a specific pixel
// x: 0 to 84, y: 0 to 48
void setPixel(int x, int y, int d) {
	if (x > 84 || y > 48) { return; }
	// The LCD has 6 rows, with 8 pixels per  row.
	// 'y_mod' is the row that the pixel is in.
	// 'y_pix' is the pixel in that row we want to enable/disable
	int y_mod = (int)(y >> 3);	// >>3 divides by 8
	int y_pix = (y-(y_mod << 3));// <<3 multiplies by 8
	int val = 1 << y_pix;
	
	/// We have to keep track of which pixels are on/off in order to
	// write the correct character out to the LCD.
	if (d){
		pixels[x][y_mod] |= val;
	} else {
		pixels[x][y_mod] &= ~val;
	}
	
	// Write the updated pixel out to the LCD
	// TODO Check if the pixel is already in the state requested,
	//      if so, don't write to LCD.
	gotoXY(x,y_mod);
	LcdWrite (1,pixels[x][y_mod]);
}

void drawLine(int x1, int y1, int x2, int y2) {
  
}

// Draw a horizontal line of width w from x,y 
void drawHorizontalLine(int x, int y, int w){
  drawHorizontalLineXY(x,x+w,y);
}

// Draw a horizontal line between x1 and x2 at row y
void drawHorizontalLineXY(int x1, int x2, int y){
  for (int i=x1;i<=x2;i++)
  {
    setPixel(i,y,1);
  }
}

// Draw a vertical line of height h from x,y
void drawVerticalLine(int x, int y, int h){
  drawVerticalLineXY(y,y+h,x);
}
// Draw a vertical line from y1 to y2 on column x
void drawVerticalLineXY(int y1, int y2, int x){
  for (int i=y1;i<=y2;i++)
  {
    setPixel(x,i,1);
  }
}

// Draw a rectangle of width w and height h from x,y
void drawRect(int x, int y, int w, int h)
{
  drawHorizontalLineXY(x,x+w,y);
  drawHorizontalLineXY(x,x+w,y+h);
  drawVerticalLineXY(y,y+h,x);
  drawVerticalLineXY(y,y+h,x+w);
}

// Draw a rectangle using p1(x1,y1) and p2(x2,y2) as corners
void drawRectXY(int x1, int y1, int x2, int y2) {
  drawHorizontalLineXY(x1,x2,y1);
  drawHorizontalLineXY(x1,x2,y2);
  drawVerticalLineXY(y1,y2,x1);
  drawVerticalLineXY(y1,y2,x2);
}

// Write data out to the LCD
void LcdWrite(byte dc, byte data) {
	digitalWrite(PIN_DC, dc);
	digitalWrite(PIN_SCE, LOW);
	shiftOut(PIN_SDIN, PIN_SCLK, MSBFIRST, data);
	digitalWrite(PIN_SCE, HIGH);
}

// Write a character out to the LCD
void LcdCharacter(char character) {
  LcdWrite(LCD_D, 0x00);
  for (int index = 0; index < 5; index++) {
    LcdWrite(LCD_D, ASCII[character - 0x20][index]);
  }
  LcdWrite(LCD_D, 0x00);
}

// Clear the LCD pixels
void LcdClear(void) {
  for (int index = 0; index < LCD_X * LCD_Y / 8; index++) {
    LcdWrite(LCD_D, 0x00);
  }
}

// Init the LCD
void LcdInitialise(void) {
  pinMode(PIN_SCE,   OUTPUT);
  pinMode(PIN_RESET, OUTPUT);
  pinMode(PIN_DC,    OUTPUT);
  pinMode(PIN_SDIN,  OUTPUT);
  pinMode(PIN_SCLK,  OUTPUT);
	
  digitalWrite(PIN_RESET, LOW);
  delay(1);
  digitalWrite(PIN_RESET, HIGH);
	
  LcdWrite( LCD_CMD, 0x21 );  // LCD Extended Commands.
  LcdWrite( LCD_CMD, 0xB0 );  // Set LCD Vop (Contrast). //B1
  LcdWrite( LCD_CMD, 0x04 );  // Set Temp coefficent. //0x04
  LcdWrite( LCD_CMD, 0x14 );  // LCD bias mode 1:48. //0x13
  LcdWrite( LCD_CMD, 0x0C );  // LCD in normal mode. 0x0d for inverse
  LcdWrite(LCD_C, 0x20);
  LcdWrite(LCD_C, 0x0C);
}

// Display a string
void LcdString(char *characters) {
  while (*characters) {
    LcdCharacter(*characters++);
  }
}

// Display an integer 
void LcdInteger(int num) {
	char buf[12];
	LcdString(itoa(num, buf, 10));
}

// Display a float, with precision
void LcdFloat(float num, int precision) {
	char buffer[25]; 
	LcdString(floatToString(buffer,num, precision)); 
}

// gotoXY routine to position cursor
// x - range: 0 to 84
// y - range: 0 to 5
void gotoXY(int x, int y) {
	LcdWrite( 0, 0x80 | x);  // Column.
	LcdWrite( 0, 0x40 | y);  // Row.  	
}


// floatToString
// http://www.arduino.cc/playground/Code/PrintFloats
char * floatToString(char * outstr, float value, int places, int minwidth, bool rightjustify) {
    // this is used to write a float value to string, outstr.  oustr is also the return value.
    int digit;
    float tens = 0.1;
    int tenscount = 0;
    int i;
    float tempfloat = value;
    int c = 0;
    int charcount = 1;
    int extra = 0;
    // make sure we round properly. this could use pow from <math.h>, but doesn't seem worth the import
    // if this rounding step isn't here, the value  54.321 prints as 54.3209
	
    // calculate rounding term d:   0.5/pow(10,places)  
    float d = 0.5;
    if (value < 0)
        d *= -1.0;
    // divide by ten for each decimal place
    for (i = 0; i < places; i++)
        d/= 10.0;    
    // this small addition, combined with truncation will round our values properly 
    tempfloat +=  d;
	
    // first get value tens to be the large power of ten less than value    
    if (value < 0)
        tempfloat *= -1.0;
    while ((tens * 10.0) <= tempfloat) {
        tens *= 10.0;
        tenscount += 1;
    }
	
    if (tenscount > 0)
        charcount += tenscount;
    else
        charcount += 1;
	
    if (value < 0)
        charcount += 1;
    charcount += 1 + places;
	
    minwidth += 1; // both count the null final character
    if (minwidth > charcount){        
        extra = minwidth - charcount;
        charcount = minwidth;
    }
	
    if (extra > 0 and rightjustify) {
        for (int i = 0; i< extra; i++) {
            outstr[c++] = ' ';
        }
    }
	
    // write out the negative if needed
    if (value < 0)
        outstr[c++] = '-';
	
    if (tenscount == 0) 
        outstr[c++] = '0';
	
    for (i=0; i< tenscount; i++) {
        digit = (int) (tempfloat/tens);
        itoa(digit, &outstr[c++], 10);
        tempfloat = tempfloat - ((float)digit * tens);
        tens /= 10.0;
    }
	
    // if no places after decimal, stop now and return
	
    // otherwise, write the point and continue on
    if (places > 0)
		outstr[c++] = '.';
	
	
    // now write out each decimal place by shifting digits one by one into the ones place and writing the truncated value
    for (i = 0; i < places; i++) {
        tempfloat *= 10.0; 
        digit = (int) tempfloat;
        itoa(digit, &outstr[c++], 10);
        // once written, subtract off that digit
        tempfloat = tempfloat - (float) digit; 
    }
    if (extra > 0 and not rightjustify) {
        for (int i = 0; i< extra; i++) {
            outstr[c++] = ' ';
        }
    }
	
	
    outstr[c++] = '\0';
    return outstr;
}







