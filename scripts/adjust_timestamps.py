#!/usr/bin/env python
#
#
import os
import sys
import shutil
import argparse
import subprocess
import pympi as pmp
import numpy as np

from operator import itemgetter
from collections import defaultdict

def get_right_key(tuple):
    """
    Function used for sorting annotations tier
    """
    return int(tuple[0][1:])

# Gladys function for extracting
# def eaf2rttm(eaf_file, uri = 'default'):
#     output_annot = []
#     eaf_file = pmp.Elan.Eaf(eaf_file)
#
#     for tier in sorted(eaf_file.tiers.keys()):
#         # if '@' not in tier and len(tier)==3:
#             # print(tier)
#         try:
#             tier_annotations = eaf_file.get_annotation_data_for_tier(tier)
#         except KeyError as e:
#             # print("Tier %s ignored..." %tier)
#             # print(e.args)
#             pass
#         parameters = eaf_file.get_parameters_for_tier(tier)
#         for annotation in tier_annotations:
#             # if 'PARENT_REF' in parameters or 'PARTICIPANT' in parameters: # necessary?
#             if ('@' not in tier and len(tier)==3): # 3 because CHI, MAN, FAN, and so on OR code for right length
#                 #print(tier)
#                 if tier=="CHI":
#                     tier_aggregate = "CHI"
#                 elif tier[0:2]=="MA" and tier[-1].isdigit():
#                     tier_aggregate = "MA0"
#                 elif tier[0:2]=="FA" and tier[-1].isdigit():
#                     tier_aggregate = "FA0"
#                 elif tier[0] in ["M", "F", "U"] and tier[1]=="C" and tier[-1].isdigit():
#                     tier_aggregate = "OC0"
#                 else:
#                     continue
#                 # tier_aggregate = tier if not tier[-1].isdigit() else tier[:-1]+'0'
#                 onset, offset = annotation[0], annotation[1]
#                 #output_annot.append((tier_aggregate, onset/1000.0, offset/1000.0))
#                 child_id = eaf_file.media_descriptors[0]["RELATIVE_MEDIA_URL"]
#                 child_id = os.path.basename(child_id).replace(".wav", "")
#                 output_annot.append((child_id, onset/1000.0, offset/1000.0-onset/1000.0, 'NAN', 'NAN', tier_aggregate))
#     print(output_annot)
#     return output_annot

# Julien function for extracting (+ debug by Marvin)
def eaf2rttm(path_to_eaf):
    """
    function to write a new .rttm file which is a transcription of the .eaf
    given as input

    """
    # in EAF, timestamps are in milliseconds, convert them to seconds
    # TODO read scale from header of EAF
    sampling_freq = 1000.0

    # read eaf file
    EAF = pmp.Elan.Eaf(path_to_eaf)

    participants = []

    # gather all the talker's names
    for k in EAF.tiers.keys():
        list_keys = EAF.tiers[k][2].keys()
        if 'TIER_ID' in list_keys:
            elem = EAF.tiers[k][2]['TIER_ID']
            if elem not in participants and "@" not in elem and len(elem) == 3:
                participants.append(elem)
        # Dirty hack to handle reliability eaf files for which there's no PARTICIPANT field ...
        elif 'PARENT_REF' in list_keys:
            elem = EAF.tiers[k][2]['PARENT_REF']
            if elem not in participants and "@" not in elem and len(elem) == 3:
                participants.append(elem)
        # Second dirty hack
        elif 'PARTICIPANT' in list_keys:
            elem = EAF.tiers[k][2]['PARTICIPANT']
            if elem not in participants and "@" not in elem and len(elem) == 3:
                participants.append(elem)

    print('participants: {}'.format(participants))
    print('tier : {}'.format(list(EAF.tiers.keys())))

    base = os.path.basename(path_to_eaf)
    name = os.path.splitext(base)[0]

    print('parsing file: {}'.format(name))
    # get the begining, ending and transcription for each annotation of
    # each tier
    rttm = []
    for participant in participants:
        if participant not in EAF.tiers.keys():
            print("Warning continue for %s" % participant)
            continue
        child_tiers = EAF.get_child_tiers_for(participant)
        child_tier_anno = {}
        for child_tier in child_tiers:
            child_tier_anno[child_tier] = EAF.tiers[child_tier][1].items()
            child_tier_anno[child_tier] = [annotation[1] for annotation in child_tier_anno[child_tier]]
            child_tier_anno[child_tier] = sorted(child_tier_anno[child_tier], key=get_right_key)
            if len(EAF.tiers[participant][0].items()) != len(child_tier_anno[child_tier]):
                print("File : " + '/'.join(path_to_eaf.split('/')[-2:]))
                print(participant + " tier length : " + str(len(EAF.tiers[participant][0].items())))
                print(child_tier + " tier length : " + str(len(child_tier_anno[child_tier])))
                print("")
        if participant not in EAF.tiers:
            print("Warning continue for %s" % participant)
            continue

        i=0
        participant_anno = sorted(EAF.tiers[participant][0].items(), key=get_right_key)

        for _, val in participant_anno:
            # Get timestamps
            start = val[0]
            end = val[1]


            t0 = EAF.timeslots[start] / sampling_freq
            length = EAF.timeslots[end] / sampling_freq - t0

            # get transcription
            transcript = val[2]

            sub_annotations = ["vcm@", "xds@", "lex@", "mwu@"]
            sub_anno_lst = []

            for sub_annotation in sub_annotations:
                if sub_annotation + participant in child_tier_anno.keys() and len(child_tier_anno[sub_annotation + participant]) != 0:
                    if len(child_tier_anno[sub_annotation + participant]) > i and child_tier_anno[sub_annotation + participant][i][0] == _:
                        sub_anno_txt = "{" + sub_annotation + ' ' + child_tier_anno[sub_annotation + participant][i][1]+"}"
                        sub_anno_lst.append(sub_anno_txt)
                    else:
                        i -= 1
                        print(
                            participant + " and " + sub_annotation + participant + " annotation ids don't match. Check the eaf. Incriminated annotation :\n" +
                                                                                   participant + " : " + _ + "\n" +
                                                                                    sub_annotation + participant + " : " + child_tier_anno[sub_annotation+participant][i][0])

            sub_anno_lst = '\t'.join(sub_anno_lst)
            if sub_anno_lst == "":
                sub_anno_lst = "<NA>"

            rttm.append((name, t0, length, transcript, sub_anno_lst, participant))
            i += 1

    # Last we check that list of participants match with what we have in the rttm
    rttm_participants = np.unique([participant for (name, t0, length, transcript, sub_anno_lst, participant) in rttm])
    if sorted(participants) != sorted(rttm_participants):
        diff = list(set(participants) - set(rttm_participants))
        for elem in diff:

            annotations = EAF.get_annotation_data_for_tier(elem)
            if len(annotations) != 0:
                raise ValueError("%s found as participant in the EAF, but not found in the rttm.\n"
                                 "Its annotation : %s" % annotations)

    return rttm

def write_rttm(output, rttm_path, annotations):
    """ write annotations to rttm_path"""

    with open(os.path.join(output, rttm_path), 'w') as fout:
        rttm_name = rttm_path.split('.')[0]
        for name, t0, length, transcript, vcm_xds, participant in annotations:
            fout.write(u"SPEAKER\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format
                       (rttm_name, 1, "%.2f" %t0, "%.2f" %length, transcript, vcm_xds, participant, "<NA>"))

def get_all_on_offs(eaf):
    """ 
        Return all the annotated intervals from the current file
    """
    EAF = pmp.Elan.Eaf(eaf)
    list_keys = EAF.tiers.keys()

    if "on_off" in list_keys and len(EAF.get_annotation_data_for_tier("on_off")) != 0:
        on_offs = EAF.get_annotation_data_for_tier("on_off")
    elif "code" in list_keys  and len(EAF.get_annotation_data_for_tier("code")) != 0:
        on_offs = EAF.get_annotation_data_for_tier("code")
    else:
        raise ValueError("Neither on_off nor code tier has been found in the eaf. \n"
                         " Tiers found %s" % list_keys)
    on_offs = [(onset/1000.0, offset/1000.0) for onset, offset, annotation_value in on_offs]
    return on_offs

def get_all_on_offs_CAS(eaf):
    """ 
        Return all the annotated intervals from the current file
    """
    EAF = pmp.Elan.Eaf(eaf)

    all_intervals = EAF.tiers['code'][0]

    on_offs = []
    for key in all_intervals:
        interv = all_intervals[key]
        _beg = interv[0]
        _end = interv[1]
        beg = EAF.timeslots[_beg]
        end = EAF.timeslots[_end]

        # store in seconds, not milliseconds
        on_offs.append((beg/1000.0, end/1000.0))

    return on_offs

def cut_audio(on_offs, input_audio, dest):
    """
        Extract from the daylong recordings the small parts that have
        been annotated
    """

    # for each annotated segment, call sox to extract the part from the
    # wav file
    # Also, write each onset/offset with 6 digits
    for on, off in on_offs:
        audio_base = os.path.splitext(input_audio)[0]
        
        wav_name = os.path.basename(audio_base)
        dir_name = os.path.split(os.path.dirname(audio_base))[-1]

        # add the necessary number of 0's to the onsets/offsets
        # to have 6 digits
        str_on = str(int(on))
        str_off = str(int(off))

        str_on = (6 - len(str_on)) * '0' + str_on
        str_off = (6 - len(str_off)) * '0' + str_off
        output_audio = '_'.join([dir_name, wav_name,
                                 str_on, str_off]) + '.wav'
        cmd = ['sox', input_audio, os.path.join(dest,  output_audio),
               'trim', str(on), str(off - on)]
        subprocess.call(cmd)

def extract_from_rttm(on_offs, rttm):
    """
        For each minute of annotation, extract the annotation of that minute
        from the transcription and write a distinct .rttm file with all the
        timestamps with reference to the begining of that segment.
    """
    sorted_rttm = sorted(rttm, key=itemgetter(1))

    # create dict { (annotated segments) -> [annotation] }
    extract_rttm = defaultdict(list)
    for on, off in on_offs:
        for name, t0, length, transcript, xds_vcm, participant in sorted_rttm:
            end = t0 + length
            if (on <= t0 < off) or (on <= end < off):
                # if the current annotation is (at least partially)
                # contained in the current segment, append it.
                # Adjust the segment to strictly fit in on-off
                t0 = max(t0, on)
                end = min(end, off)
                length = end - t0
                extract_rttm[(on, off)].append((name, t0 - on,
                                                length,
                                                transcript, xds_vcm, participant))
            elif (on > t0) and (end >= off):
                # if the current annotation completely contains the annotated
                # segment, add it also. This shouldn't happen, so print a 
                # warning also.
                #print('Warning: speaker speaks longer than annotated segment.\n'
                      # 'Please check annotation from speaker {},'
                      # 'between {} {}, segment {} {}.\n'.format(name, t0,
                      #                                          end, on, off))
                extract_rttm[(on, off)].append((name, 0, off - on,
                                                transcript, xds_vcm, participant))
            elif (end < on):
                # wait until reach segment
                continue
            elif (t0 >= off):
                # no point in continuing further since the rttm is sorted.
                break
    return extract_rttm

def main():
    """
        Take as input one eaf and wav file, and extract the segments from the
        wav that have been annotated.
    """
    parser = argparse.ArgumentParser(description="extract annotated segments")
    parser.add_argument('eaf', type=str,
                        help='''Path to the transcription of the wave file, '''
                        ''' in eaf format.''')
    # parser.add_argument('wav', type=str,
    #                     help='''Path to the wave file to treat''')
    parser.add_argument('output', type=str)
    parser.add_argument('-c', '--CAS', action='store_true',
                        help='''By default the script detects the segments'''
                        ''' using the "on_off" tier. For the CAS corpus,'''
                        ''' we should use the "code" tier.\n'''
                        ''' Enable this option when treating the CAS corpus''')
    args = parser.parse_args()

    output = args.output
    #if not os.path.isdir( os.path.join(output, 'treated')):
    #    os.makedirs(os.path.join(output, 'treated'))
    #if not os.path.isdir( os.path.join(output, 'treated', 'talker_role')):
    #    os.makedirs(os.path.join(output, 'treated', 'talker_role'))


    # read transcriptions
    complete_rttm = eaf2rttm(args.eaf)

    # extract annotated segments
    on_offs = get_all_on_offs(args.eaf)
    # cut audio files according to on_off/code tier in eaf annotations

    #print('cutting audio')
    # We don't want to cut audio here
    # cut_audio(on_offs, args.wav, output)

    # store in dict the annotations to write in rttm format
    #print('extracting rttm')
    extract_rttm = extract_from_rttm(on_offs, complete_rttm)
    # print("Here's the length")
    # print(len(extract_rttm))

    if len(extract_rttm) == 0:
        raise ValueError("No chunks have been found ! Check if on_offs or code tier are present in the eaf")
    # write one rttm file per on_off/code segment
    for key in extract_rttm:
        base = os.path.basename(args.eaf)
        
        # get the name of the corpus by taking the name of the folder and removing "raw"
        dir_name = os.path.split( os.path.dirname(args.eaf) )[-1].split('_')[-1]

        name = os.path.splitext(base)[0]
        # check is initials of annotator are in eaf name
        if '-' in name:
            name = name.split('-')[0]

        # add 0's to have exactly 6 digits (i.e. 1 second is 000001 s)
        str_on = str(int(key[0]))
        str_off = str(int(key[1]))

        str_on = (6 - len(str_on)) * '0' + str_on
        str_off = (6 - len(str_off)) * '0' + str_off

        rttm_path = '_'.join([name,
                              str_on, str_off]) + '.rttm'
        #print('writing rttm')
        write_rttm(output, rttm_path, extract_rttm[key])


if __name__ == '__main__':
    main()
