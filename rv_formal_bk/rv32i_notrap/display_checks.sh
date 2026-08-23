cd checks
for f in */status; do echo "$f: $(cat $f)"; done
cd ..
