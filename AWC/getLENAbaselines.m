all_corpora = {'CAS','BER','SOD','WAR','ROS','LUC'};


RMSE = zeros(length(all_corpora),1); % mean squared relative error across subjects
RMSE_median = zeros(length(all_corpora),1); % median squared relative error across subjects
WCE = zeros(length(all_corpora),1); % mean absolute relative error across subjects
WCE_median = zeros(length(all_corpora),1); % median absolute relative error across subjects
WCE_median_30 = zeros(length(all_corpora),1); % 3rd decile of median error
WCE_median_70 = zeros(length(all_corpora),1); % 7th decile of median error

CORR = zeros(length(all_corpora),1); % linear correlation between estimated and true counts
EST = cell(length(all_corpora),1); % estimated counts for each subject in each corpus
REF = cell(length(all_corpora),1); % true counts for each subject in each corpus
SUBID = cell(length(all_corpora),1); % subject IDs for each corpus

total_convturns = 0;          % Number of LENA conversational turns
partial_overlap_convturns = 0; % Number of LENA turns that only partially overlap with R3 annotation

for corpusiter = 1:length(all_corpora)

    corpusname = all_corpora{corpusiter};

    % Find .its files for the given corpus
    dirname = sprintf('/Users/rasaneno/speechdb/ACLEW/%s/its/*.its',corpusname);
    a = dir(dirname);

    if(~isempty(a)) % found?


        % Parse LENA .its files
        filnam = cell(length(a),1);
        LENA = cell(length(a),1);
        for k = 1:length(a)
            LENA{k} = parseLenaIts([a(k).folder '/' a(k).name]);
            filnam{k} = [a(k).folder '/' a(k).name];
        end

        % Load ACLEW R3 annotations from a .mat file

        anno_long_filename = sprintf('/Users/rasaneno/Documents/koodit/dev/WCE_journal/annofiles/anno_annotated_%s_long.mat',corpusname);

        load(anno_long_filename)

        anno_long = anno;

        % Run cleanup on orthographic transcripts
        anno_long = ACLEWstarterCleanupLongConservative(anno_long);

        % Fix audio filenames for local platform
        anno_long = fixAnnoFilenames(anno_long);

        % Get rid of non-adult talkers

        anno_long = removeNonAdultTalkers(anno_long);


        % Remove the French speaking person from short SOD training files
        if(strcmp(corpusname,'SOD'))

            tmp = find(~cellfun(@isempty,strfind(anno_long.filename,'1499')));
            ll = length(anno_long.filename);

            ff = fields(anno_long);
            for yy = 1:length(ff)
                if(length(anno_long.(ff{yy})) == ll)
                    anno_long.(ff{yy})(tmp) = [];
                end
            end

        end


        % Get full list of subject ids
        ff = cell(length(anno_long.filename),1);
        for k = 1:length(anno_long.filename)
            [~,b,~] = fileparts(anno_long.filename{k});
            ff{k} = b(5:8);
        end

        uq_subs = unique(ff);

        subj_awc = zeros(length(uq_subs),1);
        subj_ref = zeros(length(uq_subs),1);

        totwords = zeros(length(anno_long.filename),1);
        totwords_ref = zeros(length(anno_long.filename),1);

        for k = 1:length(anno_long.filename)
            s = anno_long.filename{k};


            dah = strfind(s,'e+03'); % fix weird naming errors in some of the SOD files due to timestamp rounding
            if(isempty(dah))
                seg_onset = str2num(s(end-16:end-11));
                seg_offset = str2num(s(end-9:end-4));
            elseif(dah > 70)
                seg_onset = str2num(s(end-22:end-17));
                seg_offset = str2num(s(end-15:end-8))*1e3;
            else
                seg_onset = str2num(s(end-22:end-15))*1e3;
                seg_offset = str2num(s(end-9:end-4));
            end

            [a,b,c] = fileparts(s);
            fileid = b(5:8);

            % Find correct subject ID
            si = find(strcmp(uq_subs,fileid));

            corresponding_lenafile = cellfind(filnam,fileid);

            L = LENA{corresponding_lenafile};

            % Loose criterion: segment starts before target segment
            %tmp1 = find(L.conv_offset > seg_onset);
            %tmp2 = find(L.conv_onset < seg_offset);

            % Strict criterion: segment must be fully within target segment
            %tmp1 = find(L.conv_onset >= seg_onset);
            %tmp2 = find(L.conv_offset <= seg_offset);

            % Option 3: use proportional overlap to define the number of words
            % to include from partially overlapping utterances
            % NOTE: THIS WAS USED IN THE JOURNAL ARTICLE

            tmp1 = find(L.conv_offset > seg_onset); % convs that end after segment onse
            tmp2 = find(L.conv_onset < seg_offset); % convs that start before segment offset

            i = intersect(tmp1,tmp2);

            ref = round(seg_onset):0.1:round(seg_offset);

            if(~isempty(i))
                cov = ones(length(i),1);

                % Measure overlap of the first segment
                t1 = L.conv_onset(i(1));
                t2 = L.conv_offset(i(1));

                rah = round(t1):0.1:round(t2);

                cov(1) = length(intersect(rah,ref))/length(rah);

                if(length(i) > 1)
                  t1 = L.conv_onset(i(end));
                  t2 = L.conv_offset(i(end));

                  rah = round(t1):0.1:round(t2);
                  cov(end) = length(intersect(rah,ref))/length(rah);

                end

                partial_overlap_convturns = partial_overlap_convturns+sum((cov < 1).*(cov > 0));
                total_convturns = total_convturns+length(cov);

                totwords(k) = sum(L.conv_awc(i).*cov);
                totwords_ref(k) = sum(cellfun(@length,anno_long.words{k}));

                subj_awc(si) = subj_awc(si)+sum(L.conv_awc(i).*cov);
                subj_ref(si) = subj_ref(si)+ sum(cellfun(@length,anno_long.words{k}));

            end
        end

        ref_norm = subj_ref;
        % Set zero counts to one for numerical stability
        ref_norm(ref_norm == 0) = 1;

        % Root mean square relative error
        RMSE(corpusiter) = sqrt(mean(((subj_awc-subj_ref)./ref_norm).^2))*100
        # Root median square relative error
        RMSE_median(corpusiter) = sqrt(median(((subj_awc-subj_ref)./ref_norm).^2))*100
        % Mean absolute relative error
        WCE(corpusiter) = mean(abs(subj_awc-subj_ref)./ref_norm)*100
        % Median absolute relative error
        WCE_median(corpusiter) = median(abs(subj_awc-subj_ref)./ref_norm)*100


        xyz = sort(abs(subj_awc-subj_ref)./ref_norm*100,'ascend');

        % 3rd and 7th deciles of absolute relative error
        WCE_median_30(corpusiter) = xyz(3);
        WCE_median_70(corpusiter) = xyz(7);

        % correlation
        CORR(corpusiter) = corr(subj_awc,subj_ref);
        % Raw counts
        EST{corpusiter} = subj_awc;
        REF{corpusiter} = subj_ref;
        SUBID{corpusiter} = uq_subs;
    end
end

save('/Users/rasaneno/Documents/koodit/dev/WCE_journal/results/LENA_baselines.mat','all_corpora','RMSE','RMSE_median','WCE','WCE_median','WCE_median_70','WCE_median_30','CORR','EST','REF','SUBID');
