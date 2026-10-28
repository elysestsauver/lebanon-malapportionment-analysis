# 2022 Lebanese registered voters

Data and code for the 2022 registered-voter datasets used in "Lebanon: Proportional Representation Under Consociationalism."

## Source

Lebanon's final 2022 voter lists from the Ministry of Interior, as compiled by L'Orient Today in its public Tableau workbook *Registered Voters by District*. See L'Orient Today, "Mapping Lebanon: Data and statistics": https://today.lorientlejour.com/article/1297803/data-and-statistics.html

## Files

| File | What it is |
|---|---|
| `Registered Voters by District.twbx` | Raw data: L'Orient Today's Tableau workbook |
| `extract_voters_from_twbx.py` | Step 1: copies the voter table out of the workbook |
| `District RVs Extracted from Tableau.csv` | Output of step 1: one row per registered voter (3,967,507 rows) |
| `District Pop.csv` | Tableau's district totals; step 2 checks the voter counts against them |
| `clean_registered_voters_2022.R` | Step 2: builds the datasets in `cleaned/` |
| `cleaned/voters_by_electoral_district.csv` | Final data: one row per minor district (25 rows) |
| `cleaned/voters_by_district_sect_long.csv` | Final data: one row per minor district and sect (299 rows) |
| `cleaned/diaspora_voters_by_country_district_sect.csv` | Final data: voters registered abroad, one row per country, minor district, and sect (6,133 rows) |
| `cleaned/registered_voter_counts_2022.csv` | Voter counts by district, sect, sex, and voting location |

## How to reproduce

From this folder:

    python3 -m pip install tableauhyperapi==0.0.26479
    python3 extract_voters_from_twbx.py "Registered Voters by District.twbx"
    Rscript clean_registered_voters_2022.R

The first two commands recreate `District RVs Extracted from Tableau.csv`; skip them to start from the copy included here. The last needs R 4.2 or later with the readr and dplyr packages.

Do not use Tableau's own CSV export of the voter table instead: it drops 313,375 voters.

## Variables

`voters_by_electoral_district.csv`

- `major_district`: electoral district (one of 15)
- `minor_district_en`, `minor_district_ar`: minor district, in English and Arabic
- `governorate_en`, `governorate_ar`: governorate
- `registered_total`: registered voters
- `registered_diaspora`: voters registered to vote abroad
- `registered_resident`: voters registered to vote in Lebanon (`registered_total` − `registered_diaspora`)
- `pct_diaspora`: diaspora share of registered voters, in percent
- `male`, `female`: registered voters by sex
- `pct_female`: women's share of registered voters, in percent

`voters_by_district_sect_long.csv`

- `major_district`, `minor_district_en`, `minor_district_ar`: as above
- `sect_en`: sect group (12 groups, based on each voter's personal sect; the R script lists the sects in each group)
- `registered_total`: registered voters in the sect group
- `registered_resident`: those registered to vote in Lebanon
- `pct_of_district`: the sect group's share of the minor district's registered voters, in percent

`diaspora_voters_by_country_district_sect.csv`

- `country_ar`: country where the voter is registered to vote, in Arabic as in the voter lists
- `major_district`, `minor_district_en`, `sect_en`: as above
- `registered_diaspora`: voters registered to vote in that country
