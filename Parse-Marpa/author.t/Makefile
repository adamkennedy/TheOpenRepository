
all: \
    equation_show_QDFA.out \
    equation_show_earley_sets.out \
    equation_show_bocage.out \
    equation_show_tree.out

equation_show_QDFA.out:
	echo 2+2 | perl -I../lib ../bin/mdl parse -grammar \
        ../example/equation.marpa --QDFA | \
	sed -e '/(2+2)==4/d' > $@

equation_show_earley_sets.out:
	echo 2+2 | perl -I../lib ../bin/mdl parse -grammar \
        ../example/equation.marpa --earley_sets | \
	sed -e '/(2+2)==4/d' > $@

equation_show_bocage.out:
	echo 2+2 | perl -I../lib ../bin/mdl parse -grammar \
        ../example/equation.marpa --bocage | \
	sed -e '/(2+2)==4/d' > $@

equation_show_tree.out:
	echo 2+2 | perl -I../lib ../bin/mdl parse -grammar \
        ../example/equation.marpa --tree | \
	sed -e '/(2+2)==4/d' > $@

MDL_displays.errs:
	echo | perl -I../lib ../bin/mdl parse \
	    -grammar MDL_displays.marpa 2>&1 | tee $@
