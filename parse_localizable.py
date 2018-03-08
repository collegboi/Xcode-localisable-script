#!/usr/bin/env python
from __future__ import print_function

import localizable
import csv
import xlsxwriter
import os

workbook  = xlsxwriter.Workbook('translations.xlsx')
languages = []
main_localisable_file_name = "Localizable.strings"
plist_localisable_file_name = "InfoPlist.strings"
translations = [[]]

def write_xls_file(strings_array, name):
    worksheet = workbook.add_worksheet(name)
    title_format = workbook.add_format({'text_wrap': True, 'font_color': 'white', 'bg_color': 'purple', 'border_color': 'black', 'font_size': 25})
    text_missing_format = workbook.add_format({'bg_color': 'red'})
    text_format = workbook.add_format({'color': 'black','text_wrap': True})
    worksheet.freeze_panes(1, 0)
    for index, language in enumerate(languages):
        worksheet.write(0, index, language, title_format)
        worksheet.set_column(0, index, 50)
    for index, translation in enumerate(strings_array):
        for col in range(0, len(languages)):
            try:
                row = translation[col]
                if not row:
                    worksheet.write(index +1, col, '', text_missing_format)
                else:
                    worksheet.write(index +1, col, row.decode("utf-8"), text_format)
            except IndexError:
                worksheet.write(index +1, col, '', text_missing_format)

def write_csv_file(strings_array):
    with open('translations.csv', 'wb') as csvfile:
        spamwriter = csv.writer(csvfile, quoting=csv.QUOTE_MINIMAL)
        spamwriter.writerow(languages)
        for strings_row in strings_array:
            spamwriter.writerow(strings_row)

def find_and_add(key, value, index):
    for translation in translations:
        if len(translation) > 0:
            if translation[0] == key:
                if len(translation) != (index + 1):
                    translation.append(value)

def get_strings_files(file_name):
    file_path = ""
    file_names = []
    for root, dirs, files in os.walk(file_path):
        for file in files:
            if file.endswith(file_name):
                file_path = os.path.join(root, file)
                language_folder = str(file_path).split("/")[-2]
                file_found = {
                    'lang_code': language_folder.split('.')[0],
                    'file_path': file_path
                }
                file_names.append(file_found)
    return file_names


def get_translations_keys_values(string_files):
    base_obj = [item for item in string_files if item.get('lang_code')=='Base'][0]
    if base_obj:
        base_strings = localizable.parse_strings(filename=base_obj.get('file_path'))
        languages.append('Key')
        languages.append('English')
        for base_string in base_strings:
            new_array = []
            new_array.append(base_string['key'].encode("utf-8"))
            new_array.append(base_string['value'].encode("utf-8"))
            translations.append(new_array)

        lang_index = 2
        for translation in string_files:
            if translation['lang_code'] != 'Base':
                languages.append(translation['lang_code'])
                translation_strings = localizable.parse_strings(filename=translation.get('file_path'))
                for index, es_mx_string in enumerate(translation_strings):
                    key = es_mx_string['key'].encode("utf-8")
                    value = es_mx_string['value'].encode("utf-8")
                    find_and_add(key, value, lang_index)
                lang_index += 1
    else:
        return None

string_files = get_strings_files(main_localisable_file_name)
get_translations_keys_values(string_files)
write_xls_file(translations, "Main")

translations = [[]]
string_files = get_strings_files(plist_localisable_file_name)
get_translations_keys_values(string_files)
write_xls_file(translations, "InfoPlist")

workbook.close()