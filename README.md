
# Social Housing Data

This repository contains Stata code to automatically obtain and combine social housing data from the Rijnmond region.

Each do-file performs a separate task in creating and maintaining the dataset.

- `combining.do` combines all the datasets in the `working` folder.
- `datefix.do` contains two custom commands, `datefix` and `flsort`, used for correcting observations dates and custom sorting.
- `geocoding.do` obtains and saves geographical data for each observation.
- `import.do` imports the data from the source website.
- `profile.do` initialises custom commands
- `url.do` (hidden) contains the custom command `url`, which provides my personal API key for geocoding and the url from which data is imported.

The `archive` folder contains all data as it is obtained from the source.
The `sources` folder contains previously geocoded addresses and municipality, district, and neighbourhood names for each combination of postal code and house number in the Netherlands (obtained from CBS).
Finally, the `working` folder is used when working with the datasets, to prevent accidentally changing original data.
