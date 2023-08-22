#pragma once
#include "x86.h"

void putc(char c){
    write_char(c, 0);
}

void puts(const char* str){
    while(*str){
        putc(*str);
        str++;
    }
}