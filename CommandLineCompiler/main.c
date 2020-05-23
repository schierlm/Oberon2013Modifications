#include <math.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "risc.h"
#include "risc-io.h"
#include "disk.h"

#define CPU_HZ 25000000
#define FPS 60

#define MAX_HEIGHT 2048
#define MAX_WIDTH  2048

static uint8_t buf[1024];
static uint32_t bufoff = 0, buflen = 0;
static FILE* outfile = NULL;
static bool cmddone = false;

static uint32_t Link_RStat(const struct RISC_Serial *serial) {
  return 2 + (bufoff < buflen || outfile != NULL);
}

static uint32_t Link_RData(const struct RISC_Serial *serial) {
  uint8_t ch = 0;
  if (bufoff < buflen) {
    ch = buf[bufoff];
    bufoff++;
  } else if (outfile != NULL) {
    if (fread(&ch, 1, 1, outfile) != 1) {
      fclose(outfile);
      outfile = NULL;
    }
  } else {
    ch = 0;
  }
  return ch;
}

static void Link_TData(const struct RISC_Serial *serial, uint32_t value) {
  if (value == 1)
    exit(1);
  else if (value == 0)
    cmddone = true;
  else if (value == '\r')
    printf("\n");
  else
    printf("%c", value);
}

const struct RISC_Serial link = {
  .read_status = Link_RStat,
  .read_data = Link_RData,
  .write_data = Link_TData
};

int main (int argc, char *argv[]) {
  struct RISC *risc = risc_new();
  char line[1000];
  int l;

  risc_set_serial(risc, &link);
  risc_configure_memory(risc, 8, 1024, 768);
  risc_set_spi(risc, 1, disk_new(argc > 1 ? argv[1] : NULL));
  bool done = false;
  uint32_t clock = 0;

  while (fgets(line, 1000, stdin) != NULL) {
    l = strlen(line);
    while (l > 0 & (line[l-1] == '\n' || line[l-1] == '\r')) {
      line[l-1] = '\0'; l--;
    }
    bufoff = 0; buflen = 0;
    memcpy(buf, line, l);
    buf[l] = 0;
    buflen = l + 1;
    if(line[0] == '+') {
      buf[l+1];
      outfile = fopen(&line[1], "rb");
      fseek(outfile, 0L, SEEK_END);
      l = ftell(outfile);
      fseek(outfile, 0L, SEEK_SET);
      buf[buflen] = l >> 24;
      buf[buflen+1] = l >> 16;
      buf[buflen+2] = l >> 8;
      buf[buflen+3] = l;
      buflen += 4;
    }
    cmddone = false;
    while(!cmddone) {
      clock += 1000 / FPS;
      risc_set_time(risc, clock);
      risc_run(risc, CPU_HZ / FPS);
    }
    if (outfile != NULL) {
      fclose(outfile);
      outfile = NULL;
    }
  }
  fflush(stdout);
  return 0;
}
