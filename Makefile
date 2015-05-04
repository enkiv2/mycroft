all: mycroftCore.so

mycroftCore.so: mycroftCore.o  mycroftErr.o  mycroftFact.o  mycroftList.o  mycroftStruct.o
	ld -lc -lcrypt -fPIC --shared -o mycrofCore.so mycroftCore.o mycroftErr.o mycroftFact.o mycroftList.o mycroftStruct.o

mycroftCore.o: mycroftCore.c
	cc --std=c99 -I. -fPIC -c mycroftCore.c -o mycroftCore.o

mycroftErr.o: mycroftErr.c
	cc --std=c99 -I. -fPIC -c mycroftErr.c -o mycroftErr.o

mycroftFact.o: mycroftFact.c
	cc --std=c99 -I. -fPIC -c mycroftFact.c -o mycroftFact.o

mycroftList.o: mycroftList.c
	cc --std=c99 -I. -fPIC -c mycroftList.c -o mycroftList.o

mycroftStruct.o: mycroftStruct.c
	cc --std=c99 -I. -fPIC -c mycroftStruct.c -o mycroftStruct.o


	
