%Michael Craig, 27 May 2015
%Function takes in a state abbrev and returns its full name.
%Used, as of 27 May 2015, in GatherSolarGeneration... script.

function [statename]=ConvertStateAbbrevToName(stateabbrev)

%Fill out cell array mapping states to abbreviations
stateconversion={'StateName','StateAbbrev';
    'Indiana','IN';
    'Minnesota','MN';
    'Iowa','IA';
    'Illinois','IL';
    'Kentucky','KY';
    'Wisconsin','WI';
    'North Dakota','ND';
    'South Dakota','SD';
    'Missouri','MO';
    'Michigan','MI'};

%Now look up abbreviation
staterow=find(strcmp(stateconversion(:,2),stateabbrev));
statename=stateconversion{staterow,1};