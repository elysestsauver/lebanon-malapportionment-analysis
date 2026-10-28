# Lebanon: Proportional Representation Under Consociationalism

Code and data for

> Howard, P. and St Sauver, E. "Lebanon: Proportional Representation Under Consociationalism." Forthcoming submission to a special issue of Public Choice on "The Dark Side of Proportional Representation."

**Abstract:** What are the trade-offs of representation associated with guaranteeing political communities fixed shares of a legislature? Constitutions in divided societies routinely allocate a fixed share of the legislature to ethnic, religious, or territorial groups in service of maintaining peaceful power-sharing. We measure how far from proportional representation are apportioned seats in Lebanon, whose 128 parliamentary seats have been divided among fifteen districts and eleven religious confessions by a sequence of political settlements. As the most recent census was conducted in 1932, we use data from the national voter register, the only current official count of citizens on both dimensions to compute the distribution of the electoral seats under totals proportional to the registered population. About a quarter of the chamber sits with a district or a confession other than the one that an ideal proportional allocation assigns, and reallocating all 128 seats reconciles about half of that difference. The other half is held in place by the equal division of the chamber between Christian and Muslim confessions stipulated by the Taif Agreement. We then test two reforms now under debate, imposing a single national district and variants of a recent provision that allocates seats for citizens from the Lebanese diaspora voting abroad, finding still that the existing 15-district system without the separate diaspora district fares best once seats are reallocated more closely to the proportional ideal.

## Authors

Elyse St Sauver and Peyton Howard, Department of Economics, University of California, Irvine. 
Questions: estsauve[AT]uci.edu, peytoh1[AT]uci.edu

## Sources

- **Registered voters.** Lebanon's final 2022 voter lists from Lebanon's Ministry of Interior and Municipalities, as compiled by L'Orient Today in its public Tableau workbook *Registered Voters by District*. See L'Orient Today, "Mapping Lebanon: Data and Statistics": https://today.lorientlejour.com/article/1297803/data-and-statistics.html
- **Seat allocation.** The statutory allocation of the 128 seats by qada and confession under Law 44/2017, transcribed from the Ministry of Interior and Municipalities's official results (`seats.csv`).

## Files

| File | Usage |
|---|---|
| `Registered Voters by District.twbx` | Not available due to size limits. Raw data accessible via L'Orient Today: https://today.lorientlejour.com/article/1297803/data-and-statistics.html|
| `extract_voters_from_twbx.py` | Step 1: copies the voter table out of the workbook |
| `District RVs Extracted from Tableau.csv` | Output of step 1: one row per registered voter (3,967,507 rows) |
| `District Pop.csv` | Tableau's district totals; step 2 checks the voter counts against them |
| `clean_registered_voters_2022.R` | Step 2: builds the datasets in `cleaned/` |
| `cleaned/voters_by_electoral_district.csv` | Final data: one row per minor district (25 rows) |
| `cleaned/voters_by_district_sect_long.csv` | Final data: one row per minor district and sect (299 rows) |
| `cleaned/diaspora_voters_by_country_district_sect.csv` | Final data: voters registered abroad, one row per country, minor district, and sect (6,133 rows) |
| `cleaned/registered_voter_counts_2022.csv` | Voter counts by district, sect, sex, and voting location |
| `seats.csv` | Statutory seat allocation: one row per qada and election year, with a column per confession (78 rows: 26 qadas × 2018, 2022, 2026) |
| `malapportionment.Rmd` | Step 3: computes the malapportionment indices, the reallocation counterfactuals, and the tables in the paper |

## How to reproduce

The workbook itself was too large to upload to this repository, but it's accessible from the "Mapping Lebanon: Data and Statistics" Tableau workbook produced by L'Orient Today: https://today.lorientlejour.com/article/1297803/data-and-statistics.html.

Use the downloaded `.twbx` along with the scripts in this folder:

```
python3 -m pip install tableauhyperapi==0.0.26479
python3 extract_voters_from_twbx.py "Registered Voters by District.twbx"
Rscript clean_registered_voters_2022.R
Rscript -e 'rmarkdown::render("malapportionment.Rmd")'
```

The first two commands recreate `District RVs Extracted from Tableau.csv`. The third builds `cleaned/` and needs R 4.2 or later with the `readr` and `dplyr` packages. The last renders `malapportionment.Rmd` to HTML and needs the `rmarkdown`, `tidyverse`, `knitr`, and `kableExtra` packages.

Do not use Tableau's own CSV export of the voter table instead: it drops 313,375 voters.

## What `malapportionment.Rmd` computes

Lebanon assigns each seat to a district *and* a confession (the seat is "the Maronite seat for Bcharre," not "a seat for Bcharre"). The Rmd measures how far that allocation is from proportional to registered voters at three levels:

1. **Geographic:** the 15 electoral districts
2. **Confessional:** the 12 sect groups
3. **District × confession:** all 180 district-confession cells

Two indices are reported at each level: Samuels and Snyder's malapportionment index scaled by the number of seats (SLH, readable as the number of seats in the wrong place) and the Gallagher least-squares index. The document is organized as:

| Section | Contents |
|---|---|
| 1 | Definitions of the indices and how the three levels nest |
| 2 | Data: reads `seats.csv` and `cleaned/voters_by_district_sect_long.csv` and builds the 15 × 12 district-by-confession grid |
| 3–4 | The indices for the current allocation at each level |
| 5 | Results: voters per seat, malapportionment by district and confession, the best attainable reallocation of the 128 seats with and without the 64–64 Christian–Muslim split, and a single national district |
| 6 | A separate diaspora district: three variants of the diaspora-seat provision, which domestic seats fund them, and their effect on the indices. Reads `cleaned/diaspora_voters_by_country_district_sect.csv` |
| 7 | Appendix: seats gained and lost under the unconstrained optimum |

Two data choices to be aware of:

- **The denominator is registered voters, not population.** Lebanese register in their ancestral village rather than where they live, and there has been no census since 1932. The register is the count the electoral law itself operates on.
- **`Other` sect.** Voters in the `Other` group hold no seat anywhere but stay in every voter total, so accurately reflect that they are unrepresented by any confessional seat rather than being dropped.

## Variables

### `voters_by_electoral_district.csv`

- `major_district`: electoral district (one of 15)
- `minor_district_en`, `minor_district_ar`: minor district, in English and Arabic
- `governorate_en`, `governorate_ar`: governorate
- `registered_total`: registered voters
- `registered_diaspora`: voters registered to vote abroad
- `registered_resident`: voters registered to vote in Lebanon (`registered_total` − `registered_diaspora`)
- `pct_diaspora`: diaspora share of registered voters, in percent
- `male`, `female`: registered voters by sex
- `pct_female`: women's share of registered voters, in percent

### `voters_by_district_sect_long.csv`

- `major_district`, `minor_district_en`, `minor_district_ar`: as above
- `sect_en`: sect group (12 groups, based on each voter's personal sect; the R script lists the sects in each group)
- `registered_total`: registered voters in the sect group
- `registered_resident`: those registered to vote in Lebanon
- `pct_of_district`: the sect group's share of the minor district's registered voters, in percent

### `diaspora_voters_by_country_district_sect.csv`

- `country_ar`: country where the voter is registered to vote, in Arabic as in the voter lists
- `major_district`, `minor_district_en`, `sect_en`: as above
- `registered_diaspora`: voters registered to vote in that country

### `seats.csv`

- `year`: election year (2018, 2022, or 2026). The allocation is identical in all three; `malapportionment.Rmd` uses the 2022 rows to match the voter register.
- `governorate`, `governorate_en`: governorate, in Arabic and English
- `district`: electoral district slug (e.g. `beirut_1`, `mt_leb_3`, `n_leb_2`); one of 15. Several districts span more than one qada (`n_leb_3` has four), so group by `district` for district-level counts.
- `small_district`, `small_district_en`: qada, in Arabic and English. **Use `small_district_en`.** The Arabic values came out of the source PDF with their words reordered by right-to-left extraction.
- `seats`: total seats in the qada
- `sunni`, `shia`, `druze`, `alawite`, `maronite`, `greek_catholic`, `greek_orthodox`, `evangelical`, `armenian_catholic`, `armenian_orthodox`, `minorities`: seats reserved for each confession in the qada. `evangelical` corresponds to the voter files' `Protestant` group and `minorities` to `Christian Minorities`.
- `conf_sum`: sum of the confession columns
- `balanced`: `TRUE` when `conf_sum` equals `seats`
