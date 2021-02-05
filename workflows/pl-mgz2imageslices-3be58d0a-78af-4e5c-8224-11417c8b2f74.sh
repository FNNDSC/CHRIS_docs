chrispl-run \
		--plugin   name=pl-mgz2imageslices \
		--args     "ARGS;--inputFile=subjects/100408/brain.mgz;--outputFileStem=sample;--outputFileType=png;--lookupTable=__none__;--skipAllLabels;--saveImages;--wholeVolume=entireVolume;--verbosity=5;--previous_id=104"  \
		--onCUBE   '{"protocol":"http","port":"8000","address":"117.local","user":"chris","password":"chris1234"}'
