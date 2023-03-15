import csv

"""
The idea behind the generated string is the following: We first order by the length in bytes to enable constant-time lookups.
Within each length group, we put all emojis where the skin tone is modifiable at the end to easily check within the smart contract if this is supported or not.
"""

SKIN_TONE_MODIFIABLE_EMOJIS = "☝⛹✊✋✌✍🎅🏂🏃🏄🏇🏊🏋🏌👂👃👆👇👈👉👊👋👌👍👎👏👐👦👧👨👩👮👰👱👲👳👴👵👶👷👸👼💁💂💃💅💆💇💪🕴🕵🕺🖐🖕🖖🙅🙆🙇🙋🙌🙍🙎🙏🚣🚴🚵🚶🛀🛌🤘🤙🤚🤛🤜🤝🤞🤟🤦🤰🤱🤲🤳🤴🤵🤶🤷🤸🤹🤽🤾🧑🧒🧓🧔🧕🧖🧗🧘🧙🧚🧜🧝"

emojis_by_length = {}
with open('emojis.csv') as emoji_file:
  reader = csv.reader(emoji_file, delimiter=",")
  next(reader)
  for i, row in enumerate(reader):
    if i == 420:
      break
    emoji = row[2]
    utf8_encoding = ''.join('{:02X}'.format(n) for n in emoji.encode("utf-8"))
    encoding_length = len(utf8_encoding)
    skin_tone_modifiable = emoji in SKIN_TONE_MODIFIABLE_EMOJIS
    if encoding_length in emojis_by_length:
      emojis_by_length[encoding_length].append((emoji, utf8_encoding, skin_tone_modifiable))
    else:
      emojis_by_length[encoding_length] = [(emoji, utf8_encoding, skin_tone_modifiable)]

encoding_string = ""
emoji_string = ""
for length, emoji_data in sorted(emojis_by_length.items()):
  skin_tone_modifiable = [e for e in emoji_data if e[2]]
  skin_tone_non_modfiable = [e for e in emoji_data if not e[2]]
  print("Length in bytes: {}".format(length / 2))
  print("Number of emojis without modifiable skin tone: {}".format(len(skin_tone_non_modfiable)))
  print("Number of emojis with modifiable skin tone: {}".format(len(skin_tone_modifiable)))
  print("Total: {}".format(len(skin_tone_modifiable) + len(skin_tone_non_modfiable)))
  for emoji in skin_tone_non_modfiable + skin_tone_modifiable:
    emoji_string += emoji[0]
    encoding_string += emoji[1]
print(encoding_string)
print(emoji_string)