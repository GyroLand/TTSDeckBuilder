# TTSDeckBuilder

## Overview
TTSDeckBuilder is a tool for creating decks in Tabletop Simulator (TTS).

## Features
- Create deck by copying list of cards into Tabletop Simulator
- Card information is pulled from a csv file
- Basic validation

## Usage
All the scripts are stored on an object, so you can save it then load it into your tables.

The deck builder is launched by pressing the 'Deck builder' button on the object.
Before the first deck is created, you'll need to do some setup.
- You'll need a file that list the cards your deck pulls from. This is a comma separated file (csv - though the extension doesn't matter). At the very least it needs to contain the title of the cards and the URL where the image of the card's face is stored.
- The URL where the image of the card backs is stored. 
- You'll need to setup some validation rules. Available options are:
  - Minimum number of cards in deck.
  - Maximum number of cards is deck.
  - Check uniquness. Only one card can be added in deck if it is marked as unique. For this to work there needs to be a column called 'unique' in the csv card list.
  - Limit of card copies.
  - Exclusion list that contains cards or group of cards that are not checked against the above limit.
  - Mandatory cards.
  - Banned cards.

If you don't want any validation, just create a validation rule where every field is left empty.  

### Creating the deck
After all the required settings are done, copy the list of cards into the text box on the first screen. Each individual cards need to be in separate lines and each copy needs to be listed. So for example, instead of writing *Scary monster x3*, you'll need to enter *Scary monster* in 3 separate lines.

When ready, press 'Submit'. The script will validate your list of cards against the validation rules and list the issues it finds. You can still decide to create the deck, if you don't care about having an illegal deck or you can step back and correct the list.