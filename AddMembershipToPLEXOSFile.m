%Michael Craig
%January 18, 2015
%Script for adding a row of information to the Membership sheet in a file
%for importing to PLEXOS

function [membershipdata] = AddMembershipToPLEXOSFile(membershipdata,parentclass,childclass,parentobjname,...
    childobjname)

%What to add to membership depends on type of membership being added. Also,
%collection can be determined from child class.
if strcmp(childclass,'Fuel')
    collection='Fuels';
elseif strcmp(childclass,'Generator')
    collection='Generators';
elseif strcmp(childclass,'Node')
    collection='Nodes';
elseif strcmp(childclass,'Scenario')
    collection='Scenarios';
%For storage units, Collections object depends on what parent class of
%membership is.
elseif strcmp(childclass,'Storage')
    %If assigning membership of storage to generator, need to differentiate
    %between Head and Tail Storage. Lean = head, tail = rich. The
    %name of the storage objects end in either 'Lean' or 'Rich'. So find
    %whether the name ends in 'Lean' or 'Rich' and then set collection based on
    %that.
    if strcmp(parentclass,'Generator')
        if strcmp(childobjname(end-3:end),'Lean')
            collection='Head Storage';
        elseif strcmp(childobjname(end-3:end),'Rich')
            collection='Tail Storage';
        end
    %If assigning membership of storage to constraint, then collection
    %field is Storages.
    elseif strcmp(parentclass,'Constraint')
        collection='Storages';
    end
else
    collection=childclass; %works for zone & region at least
end

membershipdatarow=size(membershipdata,1)+1;
membershipdata{membershipdatarow,1}=parentclass;
membershipdata{membershipdatarow,2}=childclass;
membershipdata{membershipdatarow,3}=collection;
membershipdata{membershipdatarow,4}=parentobjname;
membershipdata{membershipdatarow,5}=childobjname;