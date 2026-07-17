/* In-process libFuzzer harness for the aria lisp interpreter.
 *
 * Drives the full parse+eval pipeline (ar_do_string) over the fuzz input, which
 * is the same code path the standalone interpreter runs for a script file. The
 * interpreter's own setjmp/longjmp error handling (ar_try) contains aria-level
 * errors so a bad program unwinds instead of aborting the fuzzing process. The
 * built-in `exit` primitive is rebound to raise an aria error so a fuzzed
 * `(exit)` cannot terminate the fuzzer. */
#include <dirent.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "aria.h"

/* aria programs read and write files relative to the working directory (the
 * shipped scripts do `(loads "lib.lsp")`; `dumps` writes). So that an input
 * behaves identically wherever it is replayed, every execution runs in a
 * private scratch directory holding a pristine copy of lib.lsp (embedded at
 * build time from the repo's own file) and nothing else. */
static const unsigned char lib_lsp[] = {
#include "lib_lsp.inc"
};

static char sandbox[64];

static void sandbox_reset(void) {
  DIR *d = opendir(".");
  struct dirent *e;
  FILE *fp;
  if (d) {
    while ((e = readdir(d)) != NULL) {
      if (strcmp(e->d_name, ".") && strcmp(e->d_name, "..")) unlink(e->d_name);
    }
    closedir(d);
  }
  fp = fopen("lib.lsp", "wb");
  if (fp) {
    fwrite(lib_lsp, 1, sizeof(lib_lsp), fp);
    fclose(fp);
  }
}

int LLVMFuzzerInitialize(int *argc, char ***argv) {
  (void)argc;
  (void)argv;
  strcpy(sandbox, "/tmp/aria-fuzz-XXXXXX");
  if (!mkdtemp(sandbox) || chdir(sandbox) != 0) {
    fprintf(stderr, "aria harness: cannot enter scratch directory\n");
    abort();
  }
  return 0;
}

static ar_Value *fuzz_no_exit(ar_State *S, ar_Value *args) {
  (void)args;
  ar_error_str(S, "exit disabled under fuzzing");
  return NULL;
}

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  char *buf;
  ar_State *S;

  sandbox_reset();

  buf = (char *)malloc(size + 1);
  if (!buf) return 0;
  memcpy(buf, data, size);
  buf[size] = '\0';

  S = ar_new_state(NULL, NULL);
  if (!S) {
    free(buf);
    return 0;
  }

  ar_bind_global(S, "exit", ar_new_cfunc(S, fuzz_no_exit));

  ar_try(S, err, {
    ar_do_string(S, buf);
  }, {
    (void)err;
  });

  ar_close_state(S);
  free(buf);
  return 0;
}
