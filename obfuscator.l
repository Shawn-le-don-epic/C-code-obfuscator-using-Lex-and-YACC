%{                                                                                                                                                   
#include <stdio.h>                                                                                                                                   
#include <string.h>                                                                                                                                  
#include <stdlib.h>                                                                                                                                  
/* Hash table for storing identifier mappings */                                                                                                     
#define HASH_SIZE 211                                                                                                                                
struct entry {                                                                                                                                       
    char *original;                                                                                                                                  
    char *obfuscated;                                                                                                                                
    struct entry *next;                                                                                                                              
} *hash_table[HASH_SIZE];                                                                                                                            
/* Function to generate random identifier */                                                                                                         
char* generate_random_id() {                                                                                                                         
    static int counter = 0;                                                                                                                          
    char *result = malloc(10);                                                                                                                       
    sprintf(result, "v%d", counter++);                                                                                                               
    return result;                                                                                                                                   
}                                                                                                                                                    
/* Hash function */                                                                                                                                  
unsigned int hash(char *s) {                                                                                                                         
    unsigned int h = 0;                                                                                                                              
    for (; *s; s++)                                                                                                                                  
        h = h * 65599 + *s;                                                                                                                          
    return h % HASH_SIZE;                                                                                                                            
}                                                                                                                                                    
/* Lookup or create new mapping for identifier */                                                                                                    
char* get_obfuscated_name(char *original) {                                                                                                          
    unsigned int h = hash(original);                                                                                                                 
    struct entry *e = hash_table[h];                                                                                                                 
    /* Look for existing mapping */                                                                                                                  
    while (e) {                                                                                                                                      
        if (strcmp(e->original, original) == 0)                                                                                                      
            return e->obfuscated;                                                                                                                    
        e = e->next;                                                                                                                                 
    }                                                                                                                                                
    /* Create new mapping */                                                                                                                         
    e = malloc(sizeof(struct entry));                                                                                                                
    e->original = strdup(original);                                                                                                                  
    e->obfuscated = generate_random_id();                                                                                                            
    e->next = hash_table[h];                                                                                                                         
    hash_table[h] = e;                                                                                                                               
    return e->obfuscated;                                                                                                                            
}                                                                                                                                                    
%}                                                                                                                                                   
%option noyywrap                                                                                                                                     
/* Definitions */                                                                                                                                    
DIGIT       [0-9]                                                                                                                                    
ID          [a-zA-Z_][a-zA-Z0-9_]*                                                                                                                   
WS          [ \t\n]                                                                                                                                  
/* Start conditions for handling comments */                                                                                                         
%x COMMENT                                                                                                                                           
%x LINE_COMMENT                                                                                                                                      
%%                                                                                                                                                   
"/*"            { BEGIN(COMMENT); }                                                                                                                  
<COMMENT>"*/"   { BEGIN(INITIAL); }                                                                                                                  
<COMMENT>.|\n   { /* Ignore comment content */ }                                                                                                     
"//"            { BEGIN(LINE_COMMENT); }                                                                                                             
<LINE_COMMENT>\n    { ECHO; BEGIN(INITIAL); }                                                                                                        
<LINE_COMMENT>.     { /* Ignore comment content */ }                                                                                                 
"#".*\n         { ECHO; }  /* Preserve preprocessor directives */                                                                                    
"auto"|"break"|"case"|"char"|"const"|"continue"|"default"|"do"|"double"|"else"|"enum"|"extern"|"float"|"for"|"goto"|"if"|"int"|"long"|"register"|"ret
urn"|"short"|"signed"|"sizeof"|"static"|"struct"|"switch"|"typedef"|"union"|"unsigned"|"void"|"volatile"|"while"|"main"|"printf"|"scanf"|"fprintf"|"s
printf"|"snprintf"|"fscanf"|"sscanf"|"fgets"|"fputs"|"gets"|"puts"|"fread"|"fwrite"|"fopen"|"fclose"|"fseek"|"ftell"|"rewind"|"feof"|"ferror"|"cleare
rr"|"remove"|"rename"|"tmpfile"|"tmpnam"|"malloc"|"calloc"|"realloc"|"free"|"memcpy"|"memmove"|"memset"|"memcmp"|"strlen"|"strcpy"|"strncpy"|"strcat"
|"strncat"|"strcmp"|"strncmp"|"strchr"|"strrchr"|"strstr"|"strtok"|"strerror"|"atoi"|"atol"|"atoll"|"atof"|"strtol"|"strtoll"|"strtoul"|"strtoull"|"s
trtof"|"strtod"|"rand"|"srand"|"time"|"clock"|"exit"|"abort"|"abs"|"labs"|"llabs"|"div"|"ldiv"|"lldiv"|"qsort"|"bsearch"|"sin"|"cos"|"tan"|"asin"|"ac
os"|"atan"|"atan2"|"sinh"|"cosh"|"tanh"|"exp"|"log"|"log10"|"pow"|"sqrt"|"ceil"|"floor"|"fabs"|"fmod" {                                              
    ECHO;  /* Preserve keywords and standard library functions */                                                                                    
}                                                                                                                                                    
{DIGIT}+        { ECHO; }  /* Preserve numeric literals */                                                                                           
{DIGIT}+"."{DIGIT}+ { ECHO; }                                                                                                                        
\"([^\"\\]|\\.)*\"  { ECHO; }  /* Preserve string literals */                                                                                        
\'([^\'\\]|\\.)*\'  { ECHO; }  /* Preserve character literals */                                                                                     
{ID}            {                                                                                                                                    
    /* Handle identifiers */                                                                                                                         
    char *obfuscated = get_obfuscated_name(yytext);                                                                                                  
    fprintf(yyout, "%s", obfuscated);                                                                                                                
}                                                                                                                                                    
{WS}|.          { ECHO; }  /* Preserve whitespace and other characters */                                                                            
%%                                                                                                                                                   
int main(int argc, char **argv) {                                                                                                                    
    if (argc != 3) {                                                                                                                                 
        fprintf(stderr, "Usage: %s input_file output_file\n", argv[0]);                                                                              
        return 1;                                                                                                                                    
    }                                                                                                                                                
    FILE *input = fopen(argv[1], "r");                                                                                                               
    if (!input) {                                                                                                                                    
        fprintf(stderr, "Cannot open input file %s\n", argv[1]);                                                                                     
        return 1;                                                                                                                                    
    }                                                                                                                                                
    FILE *output = fopen(argv[2], "w");                                                                                                              
    if (!output) {                                                                                                                                   
        fprintf(stderr, "Cannot open output file %s\n", argv[2]);                                                                                    
        fclose(input);                                                                                                                               
        return 1;                                                                                                                                    
    }                                                                                                                                                
    yyin = input;                                                                                                                                    
    yyout = output;                                                                                                                                  
    yylex();                                                                                                                                         
    fclose(input);                                                                                                                                   
    fclose(output);                                                                                                                                  
    return 0;                                                                                                                                        
}                                                                                                                                                    
