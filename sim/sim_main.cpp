/*
 * SPDX-FileCopyrightText: 2023 Anton Maurovic <anton@maurovic.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

#include <stdio.h>
// #include <err.h>
#include <iostream>
#include <string>
#include <filesystem> // For std::filesystem::absolute() (which is only used if we have C++17)
#include "testbench.h"
using namespace std;

#include "Vsolo_squash.h"

#define DESIGN      solo_squash
#define VDESIGN     Vsolo_squash
#define MAIN_TB     Vsolo_squash_TB
#define BASE_TB     TESTBENCH<VDESIGN>

#define COLOR
#define NEW_GAME_SIGNAL
#define PAUSE_SIGNAL
//NOTE: This code is written to assume RESET_AL defined in the main design
// (i.e. reset is active-low, and hence we have reset_n signal).
// This might be specified via build process (e.g. verilator or iverilog)
// instead of directly in the code.

// #define USE_POWER_PINS //NOTE: This is automatically set in the Makefile, now.
// #define INSPECT_INTERNAL //NOTE: This is automatically set in the Makefile, now.
#ifdef INSPECT_INTERNAL
  #include "Vsolo_squash_solo_squash.h" // Needed for accessing "verilator public" stuff.
#endif

#define FONT_FILE "sim/font-cousine/Cousine-Regular.ttf"

// #define DOUBLE_CLOCK
#ifdef DOUBLE_CLOCK
  #define CLOCK_HZ    50'000'000
#else
  #define CLOCK_HZ    25'000'000
#endif

#define S1(s1) #s1
#define S2(s2) S1(s2)

#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>

// It would be nice if these could be retrieved directly from the Verilog.
// I think there's a way to do it with a "DPI" or some other Verilator method.
#define HDA 640    // Horizontal display area.
#define HFP 16     // Front porch (defined in this case to mean "coming after HDA, and before HSP").
#define HSP 96     // HSYNC pulse.
#define HBP 48     // Back porch (defined in this case to mean "coming after HSP").
#define VDA 480    // Vertical display area.
#define VFP 11     // Front porch.
#define VSP 2      // VSYNC pulse.
#define VBP 32     // Back porch.

#define HFULL (HDA+HFP+HSP+HBP)
#define VFULL (VDA+VFP+VSP+VBP)

// Extra space to show on the right and bottom of the virtual VGA screen,
// used for identifying extreme limits of things (and possible overflow):
#define EXTRA_RHS         50
#define EXTRA_BOT         50
#define H_OFFSET          HSP+HBP   // Left-hand margin during HSYNC pulse and HBP that comes before HDA.
#define V_OFFSET          VSP+VBP

#define REFRESH_PIXEL     1
#define REFRESH_FASTPIXEL 100
#define REFRESH_LINE      HFULL
#define REFRESH_10LINES   HFULL*10
#define REFRESH_80LINES   HFULL*80
#define REFRESH_FRAME     HFULL*VFULL

// SDL window size in pixels. This is what our design's timing should drive in VGA:
#define WINDOW_WIDTH  (HFULL+EXTRA_RHS)
#define WINDOW_HEIGHT (VFULL+EXTRA_BOT)
#define FRAMEBUFFER_SIZE WINDOW_WIDTH*WINDOW_HEIGHT*4

// The MAIN_TB class that includes specifics about running our design in simulation:
#include "main_tb.h"


#ifdef WINDOWS
//SMELL: For some reason, when building this under Windows, it stops building as a console command
// and instead builds as a Windows app requiring WinMain. Possibly something to do with Verilator
// or SDL2 under windows. I'm not sure yet. Anyway, this is a temporary workaround. The Makefile
// will include `-CFLAGS -DWINDOWS`, when required, in order to activate this code:
#include <windows.h>
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
  printf("DEBUG: WinMain command-line: '%s'\n", lpCmdLine);
  return main(__argc, __argv); // See: https://stackoverflow.com/a/40107581
  return 0;
}
#endif // WINDOWS


// Testbench for main design:
MAIN_TB       *TB;
bool          gQuit = false;
int           gRefreshLimit = REFRESH_FRAME;
int           gOriginalTime;
int           gPrevTime;
int           gPrevFrames;
unsigned long gPrevTickCount;
bool          gSyncLine = false;
bool          gSyncFrame = false;
bool          gHighlight = true;


// From: https://stackoverflow.com/a/38169008
// - x, y: upper left corner.
// - texture, rect: outputs.
void get_text_and_rect(
  SDL_Renderer *renderer,
  int x,
  int y,
  const char *text,
  TTF_Font *font,
  SDL_Texture **texture,
  SDL_Rect *rect
) {
  int text_width;
  int text_height;
  SDL_Surface *surface;
  SDL_Color textColor = {255, 255, 255, 0};

  surface = TTF_RenderText_Solid(font, text, textColor);
  *texture = SDL_CreateTextureFromSurface(renderer, surface);
  text_width = surface->w;
  text_height = surface->h;
  SDL_FreeSurface(surface);
  rect->x = x;
  rect->y = y;
  rect->w = text_width;
  rect->h = text_height;
}


void process_sdl_events() {
  // Event used to receive window close, keyboard actions, etc:
  SDL_Event e;
  // Consume SDL events, if any, until the event queue is empty:
  while (SDL_PollEvent(&e) == 1) {
    if (SDL_QUIT == e.type) {
      // SDL quit event (e.g. close window)?
      gQuit = true;
    } else if (SDL_KEYDOWN == e.type) {
      switch (e.key.keysym.sym) {
        case SDLK_ESCAPE:
        case SDLK_q:
          // Q or ESC key pressed, for Quit
          gQuit = true;
          break;
        case SDLK_SPACE:
          TB->pause(!TB->paused);
          break;
        case SDLK_h:
          gHighlight = !gHighlight;
          printf("Highlighting turned %s\n", gHighlight ? "ON" : "off");
          break;
        case SDLK_1:
          gRefreshLimit = REFRESH_PIXEL;
          gSyncLine = false;
          gSyncFrame = false;
          printf("Refreshing every pixel\n");
          break;
        case SDLK_9:
          gRefreshLimit = REFRESH_FASTPIXEL;
          gSyncLine = false;
          gSyncFrame = false;
          printf("Refreshing every 100 pixels\n");
          break;
        case SDLK_2:
          gRefreshLimit = REFRESH_LINE;
          gSyncLine = true;
          gSyncFrame = false;
          printf("Refreshing every line\n");
          break;
        case SDLK_3:
          gRefreshLimit = REFRESH_10LINES;
          gSyncLine = true;
          gSyncFrame = false;
          printf("Refreshing every 10 lines\n");
          break;
        case SDLK_4:
          gRefreshLimit = REFRESH_80LINES;
          gSyncLine = true;
          gSyncFrame = false;
          printf("Refreshing every 80 lines\n");
          break;
        case SDLK_5:
          gRefreshLimit = REFRESH_FRAME;
          gSyncLine = true;
          gSyncFrame = true;
          printf("Refreshing every frame\n");
          break;
        case SDLK_6:
          gRefreshLimit = REFRESH_FRAME*3;
          gSyncLine = true;
          gSyncFrame = true;
          printf("Refreshing every 3 frames\n");
          break;
        case SDLK_v:
          TB->log_vsync = !TB->log_vsync;
          printf("Logging VSYNC %s\n", TB->log_vsync ? "enabled" : "disabled");
          break;
        case SDLK_KP_PLUS:
          printf("gRefreshLimit increased to %d\n", gRefreshLimit+=1000);
          break;
        case SDLK_KP_MINUS:
          printf("gRefreshLimit decreated to %d\n", gRefreshLimit-=1000);
          break;
        case SDLK_x: // eXamine: Pause as soon as a frame is detected with any tone generation.
          TB->examine_mode = !TB->examine_mode;
          if (TB->examine_mode) {
            printf("Examine mode ON\n");
            TB->examine_condition_met = false;
          }
          else {
            printf("Examine mode off\n");
          }
          break;
        case SDLK_s: // Step-examine, basically the same as hitting X then P while already paused.
          TB->examine_mode = true;
          TB->examine_condition_met = false;
          TB->pause(false); // Unpause.
          break;
        case SDLK_f:
          printf("Stepping by 1 frame is not yet implemented!\n");
          break;
      }
    }
  }
}



void handle_control_inputs() {
  // Read the momentary state of all keyboard keys:
  auto keystate = SDL_GetKeyboardState(NULL);

  TB->m_core->reset_n     = !keystate[SDL_SCANCODE_R];
  TB->m_core->up_key_n    = !keystate[SDL_SCANCODE_UP];
  TB->m_core->down_key_n  = !keystate[SDL_SCANCODE_DOWN];
#ifdef NEW_GAME_SIGNAL
  TB->m_core->new_game_n  = !keystate[SDL_SCANCODE_N];
#endif
#ifdef PAUSE_SIGNAL
  TB->m_core->pause_n    =  !keystate[SDL_SCANCODE_P];
#endif
}


void check_performance() {
  uint32_t time_now = SDL_GetTicks();
  uint32_t time_delta = time_now-gPrevTime;

  if (time_delta >= 1000) {
    // 1S+ has elapsed, so print FPS:
    printf("Current FPS: %5.2f", float(TB->frame_counter-gPrevFrames)/float(time_delta)*1000.0f);
    // Estimate clock speed based on delta of m_tickcount:
    //SMELL: This code is really weird because for some bizarre reason I was getting mixed results
    // between Windows and Linux builds. It was as though sometimes on Windows it was treating a
    // LONG as a 32-bit integer, especially when doing *1000L
    long a = gPrevTickCount;
    long b = TB->m_tickcount;
    long c = (b-a);
    long d = time_delta;
    long hz = c / d;
    hz *= 1000L;
    // Now print long-term average:
    printf(" - Total average FPS: %5.2f", float(TB->frame_counter)/float(time_now-gOriginalTime)*1000.0f);
    // printf(" - a=%ld b=%ld c=%ld, d=%ld, hz=%ld", a, b, c, d, hz);
    printf(" - m_tickcount=");
    TB->print_big_num(TB->m_tickcount);
    printf(" (");
    TB->print_big_num(hz);
    printf(" Hz; %3ld%% of target)\n", (hz*100)/CLOCK_HZ);
    gPrevTime = SDL_GetTicks();
    gPrevFrames = TB->frame_counter;
    gPrevTickCount = TB->m_tickcount;
  }
}



void clear_freshness(uint8_t *fb) {
  // If we're not refreshing at least one full frame at a time,
  // then clear the "freshness" of pixels that haven't been updated.
  // We make this conditional in the hopes of getting extra speed
  // for higher refresh rates.
  // if (gRefreshLimit < REFRESH_FRAME) {
    // In this simulation, the 6 lower bits of each colour channel
    // are not driven by the design, and so we instead use them to
    // help visualise what region of the framebuffer has been updated
    // between SDL window refreshes (by the rendering loop forcing them on,
    // which appears as a slight brightening).
    // THIS loop clears all that between refreshes:
    for (int x = 0; x < HFULL; ++x) {
      for (int y = 0; y < VFULL; ++y) {
        fb[(x+y*WINDOW_WIDTH)*4 + 0] &= 0b1100'0000;
        fb[(x+y*WINDOW_WIDTH)*4 + 1] &= 0b1100'0000;
        fb[(x+y*WINDOW_WIDTH)*4 + 2] &= 0b1100'0000;
      }
    }
  // }
}

void overlay_display_area_frame(uint8_t *fb, int h_shift = 0, int v_shift = 0) {
  // Vertical range: Horizontal lines (top and bottom):
  if (v_shift > 0) {
    for (int x = 0; x < WINDOW_WIDTH; ++x) {
      fb[(x+(v_shift-1)*WINDOW_WIDTH)*4 + 0] |= 0b0100'0000;
      fb[(x+(v_shift-1)*WINDOW_WIDTH)*4 + 1] |= 0b0100'0000;
      fb[(x+(v_shift-1)*WINDOW_WIDTH)*4 + 2] |= 0b0100'0000;
    }
  }
  if (v_shift+VDA < WINDOW_HEIGHT) {
    for (int x = 0; x < WINDOW_WIDTH; ++x) {
      fb[(x+(VDA+v_shift)*WINDOW_WIDTH)*4 + 0] |= 0b0100'0000;
      fb[(x+(VDA+v_shift)*WINDOW_WIDTH)*4 + 1] |= 0b0100'0000;
      fb[(x+(VDA+v_shift)*WINDOW_WIDTH)*4 + 2] |= 0b0100'0000;
    }
  }
  // Horizontal range: Vertical lines (left and right):
  if (h_shift > 0) {
    for (int y = 0; y < WINDOW_HEIGHT; ++y) {
      fb[(h_shift-1+y*WINDOW_WIDTH)*4 + 0] |= 0b0100'0000;
      fb[(h_shift-1+y*WINDOW_WIDTH)*4 + 1] |= 0b0100'0000;
      fb[(h_shift-1+y*WINDOW_WIDTH)*4 + 2] |= 0b0100'0000;
    }
  }
  if (h_shift+HDA < WINDOW_WIDTH) {
    for (int y = 0; y < WINDOW_HEIGHT; ++y) {
      fb[(HDA+h_shift+y*WINDOW_WIDTH)*4 + 0] |= 0b0100'0000;
      fb[(HDA+h_shift+y*WINDOW_WIDTH)*4 + 1] |= 0b0100'0000;
      fb[(HDA+h_shift+y*WINDOW_WIDTH)*4 + 2] |= 0b0100'0000;
    }
  }
}


void fade_overflow_region(uint8_t *fb) {
  for (int x = HFULL; x < WINDOW_WIDTH; ++x) {
    for (int y = 0 ; y < VFULL; ++y) {
      fb[(x+y*WINDOW_WIDTH)*4 + 0] *= 0.95;
      fb[(x+y*WINDOW_WIDTH)*4 + 1] *= 0.95;
      fb[(x+y*WINDOW_WIDTH)*4 + 2] *= 0.95;
    }
  }
  for (int x = 0; x < WINDOW_WIDTH; ++x) {
    for (int y = VFULL; y < WINDOW_HEIGHT; ++y) {
      fb[(x+y*WINDOW_WIDTH)*4 + 0] *= 0.95;
      fb[(x+y*WINDOW_WIDTH)*4 + 1] *= 0.95;
      fb[(x+y*WINDOW_WIDTH)*4 + 2] *= 0.95;
    }
  }
}


void overflow_test(uint8_t *fb) {
  for (int x = HFULL; x < WINDOW_WIDTH; ++x) {
    for (int y = 0 ; y < VFULL; ++y) {
      fb[(x+y*WINDOW_WIDTH)*4 + 0] = 50;
      fb[(x+y*WINDOW_WIDTH)*4 + 1] = 150;
      fb[(x+y*WINDOW_WIDTH)*4 + 2] = 255;
    }
  }
  for (int x = 0; x < WINDOW_WIDTH; ++x) {
    for (int y = VFULL; y < WINDOW_HEIGHT; ++y) {
      fb[(x+y*WINDOW_WIDTH)*4 + 0] = 50;
      fb[(x+y*WINDOW_WIDTH)*4 + 1] = 150;
      fb[(x+y*WINDOW_WIDTH)*4 + 2] = 255;
    }
  }
}



int main(int argc, char **argv) {

  Verilated::commandArgs(argc, argv);
  
  TB = new MAIN_TB();
#ifdef USE_POWER_PINS
  #pragma message "Howdy! This simulation build has USE_POWER_PINS in effect"
  TB->m_core->VGND = 0;
  TB->m_core->VPWR = 1;
#else
  #pragma message "Oh hi! USE_POWER_PINS is not in effect for this simulation build"
#endif
  uint8_t *framebuffer = new uint8_t[FRAMEBUFFER_SIZE];

  //SMELL: This needs proper error handling!
  printf("SDL_InitSubSystem(SDL_INIT_VIDEO): %d\n", SDL_InitSubSystem(SDL_INIT_VIDEO));

  SDL_Window* window =
      SDL_CreateWindow(
          " Verilator VGA simulation: " S2(VDESIGN),
          SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
          WINDOW_WIDTH, WINDOW_HEIGHT,
          0
      );
  SDL_Renderer* renderer =
      SDL_CreateRenderer(
          window,
          -1,
          SDL_RENDERER_ACCELERATED
      );

  TTF_Init();
  TTF_Font *font = TTF_OpenFont(FONT_FILE, 12);
  if (!font) {
#if __cplusplus == 201703L
    std::filesystem::path font_path = std::filesystem::absolute(FONT_FILE);
#else
    string font_path = FONT_FILE;
#endif
    printf(
      "WARNING: Cannot load default font. Text rendering will be disabled.\n"
      "-- Looking for: %s\n",
      font_path.c_str()
    );
  }
  else {
    printf("Font loaded.\n");
  }
  
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
  SDL_RenderClear(renderer);
  SDL_Texture* texture =
      SDL_CreateTexture(
          renderer,
          SDL_PIXELFORMAT_ARGB8888,
          SDL_TEXTUREACCESS_STREAMING,
          WINDOW_WIDTH, WINDOW_HEIGHT
      );

  printf(
    "\n"
    "Target clock speed: "
  );
  TB->print_big_num(CLOCK_HZ);
  printf(" Hz\n");

#ifdef INSPECT_INTERNAL
  printf(
    "\n"
    "Initial state of design:\n"
    "  h        : %d\n"
    "  v        : %d\n"
    "  inPaddle : %d\n"
    "  inBallX  : %d\n"
    "  inBallY  : %d\n"
    "  ballDirX : %d\n"
    "  ballDirY : %d\n"
    "  hit      : %d\n"
    "  paddle   : %d\n"
    "  ballX    : %d\n"
    "  ballY    : %d\n"
    "\n",
    TB->m_core->DESIGN->h,
    TB->m_core->DESIGN->v,
    TB->m_core->DESIGN->inPaddle,
    TB->m_core->DESIGN->inBallX,
    TB->m_core->DESIGN->inBallY,
    TB->m_core->DESIGN->ballDirX,
    TB->m_core->DESIGN->ballDirY,
    TB->m_core->DESIGN->hit,
    TB->m_core->DESIGN->paddle,
    TB->m_core->DESIGN->ballX,
    TB->m_core->DESIGN->ballY
  );
#endif


  // printf("Starting simulation in ");
  // for (int c=3; c>0; --c) {
  //   printf("%i... ", c);
  //   fflush(stdout);
  //   sleep(1);
  // }
  printf("Cold start...\n");

  int h = 0;
  int v = 0;

  printf("Main loop...\n");

  gOriginalTime = gPrevTime = SDL_GetTicks();
  gPrevTickCount = TB->m_tickcount; // Used for measuring simulated clock speed.
  gPrevFrames = 0;

  bool count_hbp = false;
  int hbp_counter = 0; // Counter for timing the HBP (i.e. time after HSP, but before HDA).
  int h_adjust = HBP*2; // Amount to count in hbp_counter. Start at a high value and then sync back down.
  int h_adjust_countdown = REFRESH_FRAME*2;
  int v_shift = VBP*2; // This will try to find the vertical start of the image.

  while (!gQuit) {
    if (TB->done()) gQuit = true;
    if (TB->paused) SDL_WaitEvent(NULL); // If we're paused, an event is needed before we could resume.

    process_sdl_events();
    if (gQuit) break;
    if (TB->paused) continue;

    int old_reset = TB->m_core->reset_n;
    handle_control_inputs();
    if (old_reset != TB->m_core->reset_n) {
      // Reset state changed, so we probably need to resync:
      h_adjust = HBP*2;
      count_hbp = false;
      hbp_counter = 0; // Counter for timing the HBP (i.e. time after HSP, but before HDA).
      h_adjust = HBP*2; // Amount to count in hbp_counter. Start at a high value and then sync back down.
      h_adjust_countdown = REFRESH_FRAME*2;
      v_shift = VBP*2; // This will try to find the vertical start of the image.
    }

    check_performance();

    clear_freshness(framebuffer);

    //SMELL: In my RTL, I call the time that comes before the horizontal display area the BACK porch,
    // even though arguably it comes first (so surely should be the FRONT), but this swapped naming
    // comes from other charts and diagrams I was reading online at the time.

    for (int i = 0; i < gRefreshLimit; ++i) {

      if (h_adjust_countdown > 0) --h_adjust_countdown;

      bool hsync_stopped = false;
      bool vsync_stopped = false;
      TB->tick();      hsync_stopped |= TB->hsync_stopped();      vsync_stopped |= TB->vsync_stopped();      TB->examine_condition_met |= TB->m_core->speaker;
#ifdef DOUBLE_CLOCK
      TB->tick();      hsync_stopped |= TB->hsync_stopped();      vsync_stopped |= TB->vsync_stopped();      TB->examine_condition_met |= TB->m_core->speaker;
      // ^ We tick twice if the design halves the clock to produce the pixel clock.
#endif

      if (hsync_stopped) {
        count_hbp = true;
        hbp_counter = 0;
      }

      if (count_hbp) {
        // We are counting the HBP before we start the next line.
        if (hbp_counter >= h_adjust) {
          // OK, counter ran out, so let's start our next line.
          count_hbp = false;
          hbp_counter = 0;
          h = 0;
          v++;
        }
        else if (TB->m_core->green != 0) {
          // If we got here, we got a display signal earlier than the current
          // horizontal adjustment expects, so we need to adjust HBP to match
          // HDA video signal, but only after the first full frame:
          if (h_adjust_countdown <= 0) {
            h_adjust = hbp_counter;
            printf(
              "[H,V,F=%4d,%4d,%2d] "
              "Horizontal auto-adjust to %d after HSYNC\n",
              h, v, TB->frame_counter,
              h_adjust
            );
          }
        }
        else {
          h++;
          hbp_counter++;
        }
      }
      else {
        h++;
      }

      if (vsync_stopped) {
        // Start a new frame.
        v = 0;
        // if (TB->frame_counter%60 == 0) overflow_test(framebuffer);
        fade_overflow_region(framebuffer);
      }

      if (TB->m_core->green && h_adjust_countdown <= 0 && v < v_shift) {
        v_shift = v;
        printf(
          "[H,V,F=%4d,%4d,%2d] "
          "Vertical frame auto-shift to %d after VSYNC\n",
          h, v, TB->frame_counter,
          v_shift
        );
        gSyncLine = true;
        gSyncFrame = true;
      }

      int x = h;
      int y = v;

      int speaker = (TB->m_core->speaker<<6);
      int hilite = gHighlight ? 0b11'1111 : 0;

      if (x >= 0 && x < WINDOW_WIDTH && y >= 0 && y < WINDOW_HEIGHT) {

#ifdef COLOR
        int red  = (TB->m_core->red    ? 0b1100'0000 : 0) | hilite;
        int blue = (TB->m_core->blue   ? 0b1100'0000 : 0) | hilite;
#else
        int red  =                                     0  | hilite;
        int blue =                                     0  | hilite;
#endif
        int green= (TB->m_core->green  ? 0b1100'0000 : 0) | hilite;
        framebuffer[(y*WINDOW_WIDTH + x)*4 + 2] = red   | (TB->m_core->hsync ? 0 : 0b1000'0000) | speaker;  // R
        framebuffer[(y*WINDOW_WIDTH + x)*4 + 1] = green;                                                    // G
        framebuffer[(y*WINDOW_WIDTH + x)*4 + 0] = blue  | (TB->m_core->vsync ? 0 : 0b1000'0000) | speaker;  // B.
      }

      if (gSyncLine && h==0) {
        gSyncLine = false;
        break;
      }

      if (gSyncFrame && v==0) {
        gSyncFrame = false;
        break;
      }

    }

    overlay_display_area_frame(framebuffer, 0, v_shift);

    SDL_UpdateTexture( texture, NULL, framebuffer, WINDOW_WIDTH * 4 );
    SDL_RenderCopy( renderer, texture, NULL, NULL );
#ifdef INSPECT_INTERNAL
    if (font) {
      SDL_Rect rect;
      SDL_Texture *text_texture = NULL;
      string summary =
        " h="         + to_string(TB->m_core->DESIGN->h) +
        " v="         + to_string(TB->m_core->DESIGN->v) +
        " bX="        + to_string(TB->m_core->DESIGN->ballX) +
        " bY="        + to_string(TB->m_core->DESIGN->ballY) +
        " p="         + to_string(TB->m_core->DESIGN->paddle) +
        " v_shift="   + to_string(v_shift) +
        " h_adjust="  + to_string(h_adjust) +
        "";

      get_text_and_rect(renderer, 10, VFULL+10, summary.c_str(), font, &text_texture, &rect);
      if (text_texture) {
        SDL_RenderCopy(renderer, text_texture, NULL, &rect);
        SDL_DestroyTexture(text_texture);
      }
      else {
        printf("Cannot create text_texture\n");
      }
    }
#endif
    SDL_RenderPresent(renderer);
  }

  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  SDL_Quit(); //SMELL: Should use SDL_QuitSubSystem instead? https://wiki.libsdl.org/SDL2/SDL_QuitSubSystem
  if (font) TTF_CloseFont(font);
  TTF_Quit();

  delete framebuffer;

  printf("Done at %lu ticks.\n", TB->m_tickcount);
  return EXIT_SUCCESS;
}
