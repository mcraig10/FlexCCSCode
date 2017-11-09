%Michael Craig
%June 8, 2015

%Function takes in futurefleet array and column, and returns a matrix with
%the values from that row, with zeroes filled in for missing entries.

function [values] = ReturnColumnOfDataWithZerosForMissingEntries(futurefleet, datacol)

originalvalues=futurefleet(2:end,datacol);
zerorows=cellfun('isempty',originalvalues);
originalvalues(zerorows)={0};
values=cell2mat(originalvalues);
