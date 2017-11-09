# FlexCCSCode
MATLAB code for flexible CCS papers. 

This directory contains code and supporting data underlying two papers:
1) Craig, M.T., P. Jaramillo, H. Zhai, and K. Klima. (2017). The economic merits of flexible carbon capture and sequestration as a compliance strategy with the Clean Power Plan. Environmental Science & Technology, 51, 1102-1109. doi:10.1021/acs.est.6b03652.
2) Craig, M.T., H. Zhai, P. Jaramillo, and K. Klima. (2017). Trade-offs in cost and emission reductions between flexible and normal carbon capture and sequestration under carbon dioxide emission constraints. International Journal of Greenhouse Gas Control, 66, 25-34. doi:10.1016/j.ijggc.2017.09.003.

The MATLAB code aggregates data from numerous sources and structures it in a format
that can be imported directly imported to PLEXOS. We then run a UCED model in PLEXOS
on the data setup through the MATLAB script. The folder 'Analysis Scripts' includes our
MATLAB code for analyzing data output by PLEXOS.

Most data is provided in this folder. Two datasets that are not are the NREL wind 
and solar datasets. Solar data is from the NREL Transmission Grid Integration Solar PV
Generation dataset. Wind data is from NREL's Eastern Wind Dataset. 
