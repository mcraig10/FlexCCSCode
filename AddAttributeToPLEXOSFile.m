%Michael Craig
%February 11, 2015
%Script for adding a row of information to the Attribute sheet in a file
%for importing to PLEXOS

function [attributedata] = AddAttributeToPLEXOSFile(attributedata, attributeobjectname, class, attributename,...
    attributevalue)

attributerow=size(attributedata,1)+1;

attributedata{attributerow,1}=attributeobjectname;
attributedata{attributerow,2}=class; %class
attributedata{attributerow,3}=attributename; %attribute name
attributedata{attributerow,4}=attributevalue; %attribute value