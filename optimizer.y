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
[s2022103567@sflinuxonline 07.11.2024-19:16:39 - /trial4]$ cat optimizer.y                                                                           
%{                                                                                                                                                   
#include <stdio.h>                                                                                                                                   
#include <stdlib.h>                                                                                                                                  
#include <string.h>                                                                                                                                  
                                                                                                                                                     
/* Function declarations */                                                                                                                          
int yylex(void);                                                                                                                                     
void yyerror(char *s) {                                                                                                                              
        fprintf(stderr, "Error: %s\n", s);                                                                                                           
}                                                                                                                                                    
                                                                                                                                                     
/* Node structure for AST */                                                                                                                         
typedef struct Node {                                                                                                                                
    enum {                                                                                                                                           
        NODE_CONSTANT,                                                                                                                               
        NODE_IDENTIFIER,                                                                                                                             
        NODE_OPERATOR,                                                                                                                               
        NODE_ASSIGNMENT,                                                                                                                             
        NODE_RETURN,                                                                                                                                 
        NODE_WHILE,                                                                                                                                  
        NODE_BLOCK                                                                                                                                   
    } type;                                                                                                                                          


    union {                                                                                                                                          
        int constant_value;                                                                                                                          
        char *identifier;                                                                                                                            
        char operator;                                                                                                                               
    } value;                                                                                                                                         


    struct Node *left;                                                                                                                               
    struct Node *right;                                                                                                                              
    struct Node *block;                                                                                                                              
} Node;                                                                                                                                              
                                                                                                                                                     
/* Function to evaluate constant expressions */                                                                                                      
int evaluate(Node *node) {                                                                                                                           
    if (node->type == NODE_CONSTANT)                                                                                                                 
        return node->value.constant_value;                                                                                                           


    if (node->type == NODE_OPERATOR) {                                                                                                               
        int left = evaluate(node->left);                                                                                                             
        int right = evaluate(node->right);                                                                                                           


        switch(node->value.operator) {                                                                                                               
            case '+': return left + right;                                                                                                           
            case '-': return left - right;                                                                                                           
            case '*': return left * right;                                                                                                           
            case '/': return left / right;                                                                                                           
        }                                                                                                                                            
    }                                                                                                                                                
    return 0;                                                                                                                                        
}                                                                                                                                                    
                                                                                                                                                     
/* Function to optimize expressions */                                                                                                               
Node* optimize(Node *node) {                                                                                                                         
    if (!node) return NULL;                                                                                                                          


    // First optimize children                                                                                                                       
    if (node->left) node->left = optimize(node->left);                                                                                               
    if (node->right) node->right = optimize(node->right);                                                                                            
    if (node->block) node->block = optimize(node->block);                                                                                            


    // Constant folding                                                                                                                              
    if (node->type == NODE_OPERATOR &&                                                                                                               
        node->left->type == NODE_CONSTANT &&                                                                                                         
        node->right->type == NODE_CONSTANT) {                                                                                                        


        int result = evaluate(node);                                                                                                                 
        Node *constant = malloc(sizeof(Node));                                                                                                       
        constant->type = NODE_CONSTANT;                                                                                                              
        constant->value.constant_value = result;                                                                                                     
        constant->left = constant->right = NULL;                                                                                                     
        return constant;                                                                                                                             
    }                                                                                                                                                


    // Arithmetic identity optimizations                                                                                                             
    if (node->type == NODE_OPERATOR) {                                                                                                               
        // x * 1 = x                                                                                                                                 
        if (node->value.operator == '*' &&                                                                                                           
            node->right->type == NODE_CONSTANT &&                                                                                                    
            node->right->value.constant_value == 1) {                                                                                                
            return node->left;                                                                                                                       
        }                                                                                                                                            


        // x + 0 = x                                                                                                                                 
        if (node->value.operator == '+' &&                                                                                                           
            node->right->type == NODE_CONSTANT &&                                                                                                    
            node->right->value.constant_value == 0) {                                                                                                
            return node->left;                                                                                                                       
        }                                                                                                                                            


        // x * 2 = x << 1                                                                                                                            
        if (node->value.operator == '*' &&                                                                                                           
            node->right->type == NODE_CONSTANT &&                                                                                                    
            node->right->value.constant_value == 2) {                                                                                                
            node->value.operator = '<';  // Represent left shift                                                                                     
            node->right->value.constant_value = 1;                                                                                                   
            return node;                                                                                                                             
        }                                                                                                                                            
    }                                                                                                                                                


    return node;                                                                                                                                     
}                                                                                                                                                    
                                                                                                                                                     
Node* create_node(int type) {                                                                                                                        
    Node *node = malloc(sizeof(Node));                                                                                                               
    node->type = type;                                                                                                                               
    node->left = node->right = node->block = NULL;                                                                                                   
    return node;                                                                                                                                     
}                                                                                                                                                    
%}                                                                                                                                                   
                                                                                                                                                     
%union {                                                                                                                                             
    int constant;                                                                                                                                    
    char *identifier;                                                                                                                                
    struct Node *node;                                                                                                                               
}                                                                                                                                                    
                                                                                                                                                     
%token <constant> NUMBER                                                                                                                             
%token <identifier> IDENTIFIER                                                                                                                       
%token ASSIGN                                                                                                                                        
%token RETURN                                                                                                                                        
%token WHILE                                                                                                                                         
%token LBRACE RBRACE                                                                                                                                 
                                                                                                                                                     
%type <node> prog stmt expr                                                                                                                          
%left '+' '-'                                                                                                                                        
%left '*' '/'                                                                                                                                        
%right UMINUS                                                                                                                                        
                                                                                                                                                     
%%                                                                                                                                                   
                                                                                                                                                     
prog: stmt                                                                                                                                           
    | prog stmt { $$ = create_node(NODE_BLOCK); $$->left = $1; $$->right = $2; }                                                                     
    ;                                                                                                                                                
                                                                                                                                                     
stmt: RETURN expr ';' { $$ = create_node(NODE_RETURN); $$->left = $2; }                                                                              
    | WHILE '(' expr ')' stmt { $$ = create_node(NODE_WHILE); $$->left = $3; $$->right = $5; }                                                       
    | IDENTIFIER ASSIGN expr ';' { $$ = create_node(NODE_ASSIGNMENT); $$->left = create_node(NODE_IDENTIFIER); $$->left->value.identifier = $1; $$->r
ight = $3; }                                                                                                                                         
    | '{' prog '}' { $$ = create_node(NODE_BLOCK); $$->block = $2; }                                                                                 
    | expr ';' { $$ = $1; }                                                                                                                          
    ;                                                                                                                                                
                                                                                                                                                     
expr: NUMBER { $$ = create_node(NODE_CONSTANT); $$->value.constant_value = $1; }                                                                     
    | IDENTIFIER { $$ = create_node(NODE_IDENTIFIER); $$->value.identifier = $1; }                                                                   
    | expr '+' expr { $$ = create_node(NODE_OPERATOR); $$->value.operator = '+'; $$->left = $1; $$->right = $3; }                                    
    | expr '-' expr { $$ = create_node(NODE_OPERATOR); $$->value.operator = '-'; $$->left = $1; $$->right = $3; }                                    
    | expr '*' expr { $$ = create_node(NODE_OPERATOR); $$->value.operator = '*'; $$->left = $1; $$->right = $3; }                                    
    | expr '/' expr { $$ = create_node(NODE_OPERATOR); $$->value.operator = '/'; $$->left = $1; $$->right = $3; }                                    
    | '(' expr ')' { $$ = $2; }                                                                                                                      
    ;                                                                                                                                                
                                                                                                                                                     
%%
