-- test suite
function testSerialize()
	print("Testing serialization...")
	print("YES -> "..serialize(YES))
	print("NO -> "..serialize(NO))
	print("NC -> "..serialize(NC))
	print("<0.5| -> "..serialize({truth=0.5, confidence=1}))
	print("|.05> -> "..serialize({truth=1, confidence=0.5}))
	print("<0.5,0.5> -> "..serialize({truth=0.5, confidence=0.5}))
	print()
	print("test/0 -> "..serialize(createPredID("test", 0)))
	print("(test/0,YES,NO,NC) ->"..serialize({createPredID("test", 0), YES, NO, NC}))
	print()
end
function testErr()
	print("Testing error reporting...")
	print("MYC_ERR_NOERR -> "..error_string(MYC_ERR_NOERR))
	print("MYC_ERR_DETNONDET -> "..error_string(MYC_ERR_DETNONDET))
	print("MYC_ERR_UNDEFWORLD -> "..error_string(MYC_ERR_UNDEFWORLD))
	print("error_string(\"woah\") -> "..error_string("woah"))
	print("failure/0 in nil world -> "..serialize(executePredicateNA(nil, "failure", {})))
	print(MYCERR_STR)
	MYCERR_STR=""
	MYCERR=MYC_ERR_NOERR
end
function testBool()
	print("Testing booleans...")
	print("YES and NO = "..serialize(performPLBoolean(YES, NO, "and")))
	print("YES or NO = "..serialize(performPLBoolean(YES, NO, "or")))
	print("YES and NC = "..serialize(performPLBoolean(YES, NC, "and")))
	print("YES or NC = "..serialize(performPLBoolean(YES, NC, "or")))
	print("NC and NO = "..serialize(performPLBoolean(NC, NO, "and")))
	print("NC or NO = "..serialize(performPLBoolean(NC, NO, "or")))
	print()
	print("YES and <0.5, 0.5> = "..serialize(performPLBoolean(YES, {truth=0.5, confidence=0.5}, "and")))
	print("YES or <0.5, 0.5> = "..serialize(performPLBoolean(YES, {truth=0.5, confidence=0.5}, "or")))
	print("NO and <0.5, 0.5> = "..serialize(performPLBoolean(NO, {truth=0.5, confidence=0.5}, "and")))
	print("NO or <0.5, 0.5> = "..serialize(performPLBoolean(NO, {truth=0.5, confidence=0.5}, "or")))
	print("NC and <0.5, 0.5> = "..serialize(performPLBoolean(NC, {truth=0.5, confidence=0.5}, "and")))
	print("NC or <0.5, 0.5> = "..serialize(performPLBoolean(NC, {truth=0.5, confidence=0.5}, "or")))
	print()
	print("YES and <0.5| = "..serialize(performPLBoolean(YES, {truth=0.5, confidence=1}, "and")))
	print("YES or <0.5| = "..serialize(performPLBoolean(YES, {truth=0.5, confidence=1}, "or")))
	print("NO and <0.5| = "..serialize(performPLBoolean(NO, {truth=0.5, confidence=1}, "and")))
	print("NO or <0.5| = "..serialize(performPLBoolean(NO, {truth=0.5, confidence=1}, "or")))
	print("NC and <0.5| = "..serialize(performPLBoolean(NC, {truth=0.5, confidence=1}, "and")))
	print("NC or <0.5| = "..serialize(performPLBoolean(NC, {truth=0.5, confidence=1}, "or")))
	print("YES and |0.5> = "..serialize(performPLBoolean(YES, {truth=1, confidence=0.5}, "and")))
	print("YES or |0.5> = "..serialize(performPLBoolean(YES, {truth=1, confidence=0.5}, "or")))
	print("NO and |0.5> = "..serialize(performPLBoolean(NO, {truth=1, confidence=0.5}, "and")))
	print("NO or |0.5> = "..serialize(performPLBoolean(NO, {truth=1, confidence=0.5}, "or")))
	print("NC and |0.5> = "..serialize(performPLBoolean(NC, {truth=1, confidence=0.5}, "and")))
	print("NC or |0.5> = "..serialize(performPLBoolean(NC, {truth=1, confidence=0.5}, "or")))
	print()
end
function testBuiltins()
	print("Testing builtins...")
	print("builtins/0 -> "..serialize(executePredicateNA(world, "builtins", {})))
	print()
	print("equal/2(1,1) -> "..serialize(executePredicateNA(world, "equal", {1, 1})))
	print("equal/2(1,2) -> "..serialize(executePredicateNA(world, "equal", {1, 2})))
	print("gt/2(1,1) -> "..serialize(executePredicateNA(world, "gt", {1, 1})))
	print("gt/2(1,2) -> "..serialize(executePredicateNA(world, "gt", {1, 2})))
	print("lt/2(1,1) -> "..serialize(executePredicateNA(world, "lt", {1, 1})))
	print("lt/2(1,2) -> "..serialize(executePredicateNA(world, "lt", {1, 2})))
	print("gte/2(1,1) -> "..serialize(executePredicateNA(world, "gte", {1, 1})))
	print("gte/2(1,2) -> "..serialize(executePredicateNA(world, "gte", {1, 2})))
	print("lte/2(1,1) -> "..serialize(executePredicateNA(world, "lte", {1, 1})))
	print("lte/2(1,2) -> "..serialize(executePredicateNA(world, "lte", {1, 2})))
	print("equal/2(YES,YES) -> "..serialize(executePredicateNA(world, "equal", {YES, YES})))
	print("equal/2(YES,2) -> "..serialize(executePredicateNA(world, "equal", {YES, 2})))
	print("gt/2(YES,YES) -> "..serialize(executePredicateNA(world, "gt", {YES, YES})))
	print("gt/2(YES,2) -> "..serialize(executePredicateNA(world, "gt", {YES, 2})))
	print("lt/2(YES,YES) -> "..serialize(executePredicateNA(world, "lt", {YES, YES})))
	print("lt/2(YES,2) -> "..serialize(executePredicateNA(world, "lt", {YES, 2})))
	print("gte/2(YES,YES) -> "..serialize(executePredicateNA(world, "gte", {YES, YES})))
	print("gte/2(YES,2) -> "..serialize(executePredicateNA(world, "gte", {YES, 2})))
	print("lte/2(YES,YES) -> "..serialize(executePredicateNA(world, "lte", {YES, YES})))
	print("lte/2(YES,2) -> "..serialize(executePredicateNA(world, "lte", {YES, 2})))
	print("equal/2(NO,NO) -> "..serialize(executePredicateNA(world, "equal", {NO, NO})))
	print("equal/2(NO,2) -> "..serialize(executePredicateNA(world, "equal", {NO, 2})))
	print("gt/2(NO,NO) -> "..serialize(executePredicateNA(world, "gt", {NO, NO})))
	print("gt/2(NO,2) -> "..serialize(executePredicateNA(world, "gt", {NO, 2})))
	print("lt/2(NO,NO) -> "..serialize(executePredicateNA(world, "lt", {NO, NO})))
	print("lt/2(NO,2) -> "..serialize(executePredicateNA(world, "lt", {NO, 2})))
	print("gte/2(NO,NO) -> "..serialize(executePredicateNA(world, "gte", {NO, NO})))
	print("gte/2(NO,2) -> "..serialize(executePredicateNA(world, "gte", {NO, 2})))
	print("lte/2(NO,NO) -> "..serialize(executePredicateNA(world, "lte", {NO, NO})))
	print("lte/2(NO,2) -> "..serialize(executePredicateNA(world, "lte", {NO, 2})))
	print()
	print("print/1(\"Hello, world!\") -> "..serialize(executePredicateNA(world, "print", {"Hello, world!"})))
	print()
end
function testCore()
	print("Testing core...")
	world={}
	truePred=createPredID("true", 0)
	falsePred=createPredID("false", 0)
	ncPred=createPredID("noConfidence", 0)
	synPred1=createPredID("synthetic", 1)
	synPred2=createPredID("synthetic", 2)
	synPred3=createPredID("synthetic", 3)
	synPred4=createPredID("synthetic", 4)
	synPred5=createPredID("synthetic", 5)
	synPred6=createPredID("synthetic", 6)
	synPred7=createPredID("synthetic", 7)
	createFact(world, truePred, "()", YES)
	createFact(world, falsePred, "()", NO)
	createFact(world, ncPred, "()", NC)
	createDef(world, synPred1, {truePred, falsePred}, {{{},{}}, {{},{}}}, "and", true)
	createDef(world, synPred2, {truePred, falsePred}, {{{},{}}, {{},{}}}, "or", true)
	createDef(world, synPred3, {truePred, ncPred}, {{{},{}}, {{},{}}}, "and", true)
	createDef(world, synPred4, {truePred, ncPred}, {{{},{}}, {{},{}}}, "or", true)
	createDef(world, synPred5, {ncPred, falsePred}, {{{},{}}, {{},{}}}, "and", true)
	createDef(world, synPred6, {ncPred, falsePred}, {{{},{}}, {{},{}}}, "or", true)
	createDef(world, synPred7, {truePred, falsePred, truePred}, {{{},{}}, {{},{}}, {{}, {}}}, "or", true)
	print()
	printWorld(world)
	print()
	print("true/0 -> "..serialize(executePredicateNA(world, "true", {})))
	print("false/0 -> "..serialize(executePredicateNA(world, "false", {})))
	print("noConfidence/0 ->"..serialize(executePredicateNA(world, "noConfidence", {})))
	print()
	print("synthetic/1 -> "..serialize(executePredicateNA(world, "synthetic", {1})))
	print("synthetic/2 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2})))
	print("synthetic/3 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3})))
	print("synthetic/4 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3, 4})))
	print("synthetic/5 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3, 4, 5})))
	print("synthetic/6 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3, 4, 5, 6})))
	print("synthetic/7 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3, 4, 5, 6, 7})))
	print()
	print("printPred/1(true/0) -> "..serialize(executePredicateNA(world, "printPred", {truePred})))
	print("printWorld/0 -> "..serialize(executePredicateNA(world, "printWorld", {})))
	print(MYCERR_STR)
	print()
end
function testParse()
	print("Testing parse...")
	print(parseLine({}, "det true(x, y, z) :- YES."))
end
function testHelp()
	print("Testing online help...")
	print("help/0 -> "..serialize(executePredicateNA({}, "help", {})))
	print("help/1(\"banner\") -> "..serialize(executePredicateNA({}, "help", {"banner"})))
	print("help/1(\"syntax\") -> "..serialize(executePredicateNA({}, "help", {"syntax"})))
	print("help/1(\"version\") -> "..serialize(executePredicateNA({}, "help", {"version"})))
	print("help/1(\"copying\") -> "..serialize(executePredicateNA({}, "help", {"copying"})))
	print()
	for k,v in pairs(builtins) do
		print("help/1("..serialize(k)..") -> "..serialize(executePredicateNA({}, "help", {k})))
	end
end
function testFile()
	main({"test.myc"})
end
function test()
	testSerialize()
	testErr()
	testBool()
	testCore()
	testBuiltins()
	testParse()
	testHelp()
	testFile()
end
