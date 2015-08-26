# Mycroft internals: error handling

Each 'world' contains an integer variable MYCERR and a string variable MYCERR_STR. MYCERR is set to 0 if no error has occurred. MYCERR_STR is set to the traceback of the last error that occurred (along with human-readable error name and error message, the predicate in which it occurred, and the signature of each predicate up the stack that doesn't catch it). If caught, MYCERR is set to 0 and MYCERR_STR is set to empty string.

