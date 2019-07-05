function anno = ACLEWstarterCleanupLongConservative(anno)


if(iscell(anno))
    anno = convertannostructstyle(anno);
end


% Remove all on_off tags

for j = 1:length(anno.words)
    if(~isempty(anno.talker_id_utterance{j}))
    if(strcmp(anno.talker_id_utterance{j}{1},'on_off'))
       anno.words{j} = anno.words{j}(2:end);
       anno.utterance{j} = anno.utterance{j}(2:end);
       anno.t_onset_utterance{j} = anno.t_onset_utterance{j}(2:end);
       anno.t_offset_utterance{j} = anno.t_offset_utterance{j}(2:end);
       anno.addressee{j} = anno.addressee{j}(2:end);
       anno.talker_id_utterance{j} = anno.talker_id_utterance{j}(2:end);
    end
    end
end



% Remove all utterances that do not have words at all

for j = 1:length(anno.words)

    tmp = find(cellfun(@isempty,anno.words{j}));
    isok = ones(length(anno.words{j}),1);
    isok(tmp) = 0;

    ffs = fieldnames(anno);
    for ss = 1:length(ffs)
        if(~strcmp(ffs{ss},'filename'))
        anno.(ffs{ss}){j} = anno.(ffs{ss}){j}(isok > 0);
        end
    end

end


include_nonlinguistics = 0;    % count non-linguistic communicatives as words?
discard_unclear_speech = 1;    % discard words with xxx annotations (untranscribed unclear speech)


banned_markers = {'0.','xxx'};  % markers that discard the word when contained within a word
banned_words_wholeword = {'.','?','!',',','>','<','&','=','0','0.','hm','um.','uh,'}; % markers that discard the word when make up the whole word
banned_markers_sentence = {};  % markers that, when making up a word, disqualify the whole sentence

if(~include_nonlinguistics)
    banned_markers = union(banned_markers,'&='); % non-linguistic sounds
end
if(discard_unclear_speech)
   banned_markers = union(banned_markers,'xxx');
   banned_markers = union(banned_markers,'xxx.');
   banned_markers = union(banned_markers,'yyy.');
   banned_markers = union(banned_markers,'<yyy>');
   banned_markers = union(banned_markers,'<xxx>');
   banned_markers = union(banned_markers,'<xxx');
   banned_markers = union(banned_markers,'xxx>');
   banned_markers = union(banned_markers,'xxx!');
   banned_markers = union(banned_markers,'xxx?');
   banned_markers = union(banned_markers,'xxx,');
   banned_markers = union(banned_markers,'d-xxx');
   banned_markers = union(banned_markers,'-<xxx>');
   banned_markers = union(banned_markers,{'sh.','hm?','laughs].','laughs.','kisses.','<mm>','sings].','mm-hm','mm-hm.','imitates]'});
end




% Go through the utterances and fix whitespace errors in annotations
for j = 1:length(anno.words)
    for jj = 1:length(anno.words{j})
        inds_to_remove = [];
        for k = 1:length(anno.words{j}{jj})-1
            if(strcmp(anno.words{j}{jj}{k},'[') && strcmp(anno.words{j}{jj}{k+1},':'))
                anno.words{j}{jj}{k} = '[:';
                inds_to_remove = [inds_to_remove;k+1];
            end

            if(strcmp(anno.words{j}{jj}{k},'!') && strcmp(anno.words{j}{jj}{k+1},'='))
                anno.words{j}{jj}{k} = '!=';
                inds_to_remove = [inds_to_remove;k+1];
            end
            if(strcmp(anno.words{j}{jj}{k},'&') && strcmp(anno.words{j}{jj}{k+1},'='))
                anno.words{j}{jj}{k} = '&=';
                inds_to_remove = [inds_to_remove;k+1];
            end

            if(strcmp(anno.words{j}{jj}{k},'[') && strcmp(anno.words{j}{jj}{k+1},'!='))
                anno.words{j}{jj}{k} = '[!=';
                inds_to_remove = [inds_to_remove;k+1];
            end

            if(strcmp(anno.words{j}{jj}{k},'[!') && strcmp(anno.words{j}{jj}{k+1}(1),'='))
                anno.words{j}{jj}{k} = '[!=';
                anno.words{j}{jj}{k+1} = anno.words{j}{jj}{k+1}(2:end);
            end
        end
        anno.words{j}{jj}(inds_to_remove) = [];
    end
end

% Parse spoken vs. literal tags of form said [: said_literal]
for j = 1:length(anno.words)
    for jj = 1:length(anno.words{j})
        tmp = cellfun(@isempty,anno.words{j}{jj});
        anno.words{j}{jj}(tmp) = [];
        a = union(cellfind(anno.words{j}{jj},'[:'),cellfind(anno.words{j}{jj},'[-'));
    a = union(a,cellfind(anno.words{j}{jj},'[='));
    a = union(a,cellfind(anno.words{j}{jj},'[!='));
        if(a)
            inds_to_remove = [];
            for i = 1:length(a)
                b = cellfind(anno.words{j}{jj}(a(i):end),']')+a(i)-1;
                if(isempty(b))
                    b = length(anno.words{j}{jj});
                end
                %    pause;
                if((~isempty(a) && ~isempty(b(1))))
                    if(size(inds_to_remove,1) < size(inds_to_remove,1))
                        inds_to_remove = [inds_to_remove a(i):b(1)];
                    else
                        inds_to_remove = [inds_to_remove;(a(i):b(1))'];
                    end
                    %anno.words{j}{jj}(a(i):b(1)) = [];
                else
                    error('Something went wrong.');
                end
            end
            anno.words{j}{jj}(inds_to_remove) = [];
        end
    end
end


% Parse speaking style tags (e.g., [=! laughs])
for j = 1:length(anno.words)
    for jj = 1:length(anno.words{j})
        tmp = cellfun(@isempty,anno.words{j}{jj});
        anno.words{j}{jj}(tmp) = [];
        a = union(cellfind(anno.words{j}{jj},'[!='),cellfind(anno.words{j}{jj},'[=!'));
        if(a)
            inds_to_remove = [];
            for i = 1:length(a)
                b = cellfind(anno.words{j}{jj}(a(i):end),']')+a(i)-1;
                %    pause;
                if(isempty(b))
                    b = length(anno.words{j}{jj});
                end

                if((~isempty(a) && ~isempty(b(1))))
                    if(size(inds_to_remove,1) < size(inds_to_remove,1))
                        inds_to_remove = [inds_to_remove a(i):b(1)];
                    else
                        inds_to_remove = [inds_to_remove;(a(i):b(1))'];
                    end
                    %anno.words{j}{jj}(a(i):b(1)) = [];
                else
                    error('Something went wrong.');
                end
            end
            anno.words{j}{jj}(inds_to_remove) = [];
        end
    end
end


% Parse overlap tags (???) (e.g., [+ CHI0])
for j = 1:length(anno.words)
    for jj = 1:length(anno.words{j})
    tmp = cellfun(@isempty,anno.words{j}{jj});
    anno.words{j}{jj}(tmp) = [];
    a = cellfind(anno.words{j}{jj},'[+');
    if(a)
        inds_to_remove = [];
        for i = 1:length(a)
            b = cellfind(anno.words{j}{jj}(a(i):end),']')+a(i)-1;
            %    pause;
            if((~isempty(a) && ~isempty(b(1))))
                if(size(inds_to_remove,1) < size(inds_to_remove,1))
                    inds_to_remove = [inds_to_remove a(i):b(1)];
                else
                    inds_to_remove = [inds_to_remove;(a(i):b(1))'];
                end
                %anno.words{j}{jj}(a(i):b(1)) = [];
            else
                error('Something went wrong.');
            end
        end
        anno.words{j}{jj}(inds_to_remove) = [];
    end
    end
end

% Other non-word contents
for j = 1:length(anno.words)
    for jj = 1:length(anno.words{j})
    % Remove words that contain banned_markers
    inds_to_remove = [];
    for k = 1:length(banned_markers)
        a = cellfind(anno.words{j}{jj},banned_markers{k});
        if(~isempty(a))
            if(size(inds_to_remove,1) > 1)
                inds_to_remove = [inds_to_remove;a];
            else
                inds_to_remove = [inds_to_remove a];
            end
        end
    end

    % Remove full utterances that contain banned_markers_sentence
    for k = 1:length(banned_markers_sentence)
       a = find(strcmp(anno.words{j}{jj},banned_markers_sentence{k}));
       if(~isempty(a))
          inds_to_remove = [1:length(anno.words{j}{jj})]';
       end
    end

    % Remove words that exactly match to banned_words_wholeword
    for k = 1:length(banned_words_wholeword)
       a = find(strcmp(anno.words{j}{jj},banned_words_wholeword{k}));
       if(~isempty(a))
           if(size(inds_to_remove,1) > 1)
                inds_to_remove = [inds_to_remove;a];
            else
                inds_to_remove = [inds_to_remove a];
            end
       end
    end
    anno.words{j}{jj}(unique(inds_to_remove)) = [];
    end
end



% Handle repetitions [xN]
for j = 1:length(anno.words)
    for jj = 1:length(anno.words{j})
        for k = 1:length(anno.words{j}{jj})
            if(strfind(anno.words{j}{jj}{k},'[x'))
                if(length(anno.words{j}{jj}{k}) > 2)
                if(k > 1)
                    word_to_rep = anno.words{j}{jj}{k-1};
                else
                    word_to_rep = 'genrep';
                end
                reps = ceil(str2num(anno.words{j}{jj}{k}(3)));


                if(reps > 0)
                    ss = cell(1,reps);

                    for yy = 1:reps
                        ss{yy} = word_to_rep;
                    end
                    newwords = [anno.words{j}{jj}(1:k-1) ss anno.words{j}{jj}(k+1:end)];
                    anno.words{j}{jj} = newwords;
                end



                end
            end
        end
    end
end


for j = 1:length(anno.words)

    isok = ones(length(anno.words{j}),1);
    for k = 1:length(anno.words{j})
        if(isempty(anno.words{j}{k}))
            isok(k) = 0;
        end
    end

    fprintf('Rejected %d utterances.\n',sum(isok == 0));

    tmp = anno.addressee;
    a = find(cellfun(@length,tmp) == 0);

    isok(a) = 0;

    % Keep only fields for valid utterances
    ffs = fieldnames(anno);
    for ss = 1:length(ffs)
        if(~strcmp(ffs{ss},'filename'))
        anno.(ffs{ss}){j} = anno.(ffs{ss}){j}(isok > 0);
        end
    end

end

% Add language tags for each utterance

filetags = {'BER','CAS','ROS','SOD','WAR','ROW','tseltal','LUC'};
languages = {'english','tzeltal','spanish','english','english','english','tzeltal','english'};

anno.language = cell(length(anno.filename),1);

for k = 1:length(anno.filename)

    s = anno.filename{k};
    for j = 1:length(filetags)
       if(~isempty(strfind(s,filetags{j})))
          anno.language{k} = languages{j};
          anno.subcorpus{k} = filetags{j};
       end
    end
    if(isempty(anno.language{k}))
       error('Couldn''t find matching language. Please define language of the file in ACLEWstarterCleanupLongConservative.m');
    end
end
