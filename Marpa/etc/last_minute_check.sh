make build
(cd ../author.t; make -B)
make -B perlcritic
wc -l perlcritic.errs
