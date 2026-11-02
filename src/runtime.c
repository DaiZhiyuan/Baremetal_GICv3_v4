// ----------------------------------------------------------
// GNU C runtime initialisation and semihosting printf
//
// Copyright (C) Arm Limited, 2019-2021 All rights reserved.
// ----------------------------------------------------------

#include <stdarg.h>
#include <stdint.h>

#define OUTPUT_BUFFER_SIZE 256

struct output_buffer
{
  char data[OUTPUT_BUFFER_SIZE];
  unsigned int length;
  int total;
};

extern void initialise_monitor_handles(void);
extern int _write(int fd, const char *buf, int len);

static void output_flush(struct output_buffer *out)
{
  if (out->length != 0)
  {
    _write(1, out->data, (int)out->length);
    out->length = 0;
  }
}

static void output_char(struct output_buffer *out, char c)
{
  if (out->length == OUTPUT_BUFFER_SIZE)
    output_flush(out);

  out->data[out->length++] = c;
  out->total++;
}

static void output_string(struct output_buffer *out, const char *s)
{
  while (*s != '\0')
    output_char(out, *s++);
}

static unsigned int output_number(struct output_buffer *out,
                                  uint64_t value,
                                  unsigned int base,
                                  int width,
                                  char padding)
{
  static const char digits[] = "0123456789abcdef";
  char tmp[32];
  unsigned int count = 0;
  unsigned int length = 0;

  do
  {
    tmp[length++] = digits[value % base];
    value /= base;
  } while (value != 0);

  while ((int)length < width)
  {
    output_char(out, padding);
    width--;
  }

  while (length != 0)
  {
    output_char(out, tmp[--length]);
    count++;
  }

  return count;
}

void gnu_runtime_init(void)
{
  initialise_monitor_handles();
}

int printf(const char *format, ...)
{
  struct output_buffer out;
  va_list args;
  const char *p;

  out.length = 0;
  out.total = 0;

  va_start(args, format);

  for (p = format; *p != '\0'; p++)
  {
    int width = 0;
    int is_long = 0;
    char padding = ' ';

    if (*p != '%')
    {
      output_char(&out, *p);
      continue;
    }

    p++;

    if (*p == '%')
    {
      output_char(&out, '%');
      continue;
    }

    if (*p == '0')
    {
      padding = '0';
      p++;
    }

    while ((*p >= '0') && (*p <= '9'))
    {
      width = (width * 10) + (*p - '0');
      p++;
    }

    if (*p == 'l')
    {
      is_long = 1;
      p++;
    }

    switch (*p)
    {
      case 'd':
      {
        int value = va_arg(args, int);
        uint64_t magnitude;

        if (value < 0)
        {
          output_char(&out, '-');
          magnitude = (uint64_t)(-(int64_t)value);
        }
        else
        {
          magnitude = (uint64_t)value;
        }

        output_number(&out, magnitude, 10, width, padding);
        break;
      }

      case 'u':
        output_number(&out, (uint64_t)va_arg(args, unsigned int), 10, width, padding);
        break;

      case 'x':
        if (is_long)
          output_number(&out, (uint64_t)va_arg(args, unsigned long), 16, width, padding);
        else
          output_number(&out, (uint64_t)va_arg(args, unsigned int), 16, width, padding);
        break;

      case 's':
        output_string(&out, va_arg(args, const char *));
        break;

      default:
        output_char(&out, '%');
        if (*p != '\0')
          output_char(&out, *p);
        break;
    }
  }

  va_end(args);
  output_flush(&out);

  return out.total;
}

// ----------------------------------------------------------
// End of runtime.c
// ----------------------------------------------------------
