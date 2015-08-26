# Internals: composite truth value manipulation and canonicalization

Malformed truth values are canonicalized to NC. Truth values with zero confidence are canonicalized to NC. Truth values have their components clipped to the range from 0 to 1 inclusive. 

CTV boolean arithmetic operates as follows:

	<A,B> AND <C,D> => <A*C,B*D>
	<A,B> OR <C,D> => <A*B+C*D-A*C,min(B,D)>

