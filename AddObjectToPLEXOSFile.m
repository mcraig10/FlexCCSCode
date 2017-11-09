%Michael Craig
%January 18, 2015
%Script for adding a row of information to the Object sheet in a file
%for importing to PLEXOS

function [objectdata] = AddObjectToPLEXOSFile(objectdata,object,objname)

objectdatarow=size(objectdata,1)+1;
objectdata{objectdatarow,1}=object;
objectdata{objectdatarow,2}=objname;