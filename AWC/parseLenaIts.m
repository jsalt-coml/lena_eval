function LENA = parseLenaIts(filnam)


D = importdata(filnam);



segment_rows = find(~cellfun(@isempty,strfind(D,'Segment spkr')));

spkr = cell(length(segment_rows),1);
onset = zeros(length(segment_rows),1);
offset = zeros(length(segment_rows),1);

for k = 1:length(segment_rows)
    s = strsplit(D{segment_rows(k)},' ');
    
    tmp = cellfind(s,'spkr');
    
    spkr{k} = s{tmp}(7:end-1);
    
     tmp = cellfind(s,'startTime');
    onset(k) = str2num(s{tmp}(14:end-2));
    
     tmp = cellfind(s,'endTime');
    offset(k) = str2num(s{tmp}(12:end-2));
end

exclude_list = {'SIL','TVN','TVF','OLF','OLN','NOF','NON'};

to_remove = [];
for k = 1:length(exclude_list)
    to_remove = union(to_remove,find(strcmp(spkr,exclude_list{k})));
end

spkr(to_remove) = [];
onset(to_remove) = [];
offset(to_remove) = [];

% Parse conversations


conv_rows = find(~cellfun(@isempty,strfind(D,'Conversation num')));

onset_conv = zeros(length(conv_rows),1);
offset_conv = zeros(length(conv_rows),1);
awc = zeros(length(conv_rows),1);

for k = 1:length(conv_rows)
    s = strsplit(D{conv_rows(k)},' ');
    
    tmp = cellfind(s,'adultWordCnt');
    
    awc(k) = str2num(s{tmp}(15:end-1));
    
     tmp = cellfind(s,'startTime');
    onset_conv(k) = str2num(s{tmp}(14:end-2));
    
     tmp = cellfind(s,'endTime');
    offset_conv(k) = str2num(s{tmp}(12:end-3));
end

LENA.conv_awc = awc;
LENA.conv_onset = onset_conv;
LENA.conv_offset = offset_conv;
LENA.utt_spkr = spkr;
LENA.utt_onset = onset;
LENA.utt_offset = offset;

