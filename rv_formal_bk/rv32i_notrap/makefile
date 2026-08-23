TYPE1 = make -C checks -j2
TYPE2 = make -C checks -j$(nproc)
run:
	python3 ../../checks/genchecks.py
	make -C checks -j4
	bash display_checks.sh
