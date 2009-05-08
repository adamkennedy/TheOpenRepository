
MODULE = PPI::XS::Tokenizer		PACKAGE = PPI::XS::Tokenizer

Tokenizer *
Tokenizer::new()
 
void
Tokenizer::DESTROY()

LineTokenizeResults
Tokenizer::tokenizeLine( line )
    char* line
  CODE:
    RETVAL = THIS->tokenizeLine(line, (ulong) strlen(line));
  OUTPUT:
    RETVAL

