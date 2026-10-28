# ==============================================================================
# clean_registered_voters_2022.R
#
# Builds the 2022 registered-voter datasets used in "Lebanon: Proportional Representation Under
# Consociationalism" from the 2022 Lebanese voter rolls, as stored
# in the Tableau workbook "Registered Voters by District.twbx".
#
# Inputs (in raw_dir)
#   District RVs Extracted from Tableau.csv
#       One row per registered voter (3,967,507 rows). Created from the
#       workbook by extract_voters_from_twbx.py, which reads the workbook's data
#       extract directly. Do not use Tableau's own CSV export of this table
#       instead: it is missing 313,375 voters.
#   District Pop.csv
#       Tableau's district totals, exported from the workbook's "District Pop"
#       sheet. Used only to check the voter records.
#
# Outputs (in out_dir)
#   voters_by_electoral_district.csv  One row per minor district (25 rows):
#                                     registered voters, residents vs. diaspora,
#                                     men vs. women.
#   voters_by_district_sect_long.csv  One row per minor district x sect.
#   diaspora_voters_by_country_district_sect.csv
#                                     Voters registered to vote abroad, one row
#                                     per country x minor district x sect.
#   registered_voter_counts_2022.csv  Intermediate file: de-identified counts of
#                                     voters by district, sect, sex, and country
#                                     where registered to vote abroad.
#
# Format of District Pop.csv: like all Tableau "CSV" exports, it is
# tab-delimited text encoded as UTF-16LE, with thousands separators in the
# numbers ("134,825"). It is read with read_tsv() and an explicit encoding
# below, not with read_csv().
#
# Step 1 reads only the six fields it needs from the voter file (not names,
# dates of birth, etc.) and immediately collapses them to counts. If the voter
# file is not present, Step 1 instead reads the counts saved by an earlier run.
#
# Nothing is saved unless the voter records add up exactly to Tableau's own
# district totals (Step 3).
#
# Requirements: R 4.2 or later, with the readr and dplyr packages. Run the
# script with its own folder as the working directory. This file is UTF-8
# encoded because it contains Arabic text.
# ==============================================================================

library(readr)
library(dplyr)

raw_dir <- "."         # folder containing the raw files
out_dir <- "cleaned"   # folder the cleaned datasets are written to

voter_file   <- file.path(raw_dir, "District RVs Extracted from Tableau.csv")
tableau_file <- file.path(raw_dir, "District Pop.csv")
counts_file  <- file.path(out_dir, "registered_voter_counts_2022.csv")

# Reads a Tableau export (District Pop.csv): UTF-16LE, tab-delimited, every
# column as text, and empty cells kept as "" (not converted to NA).
read_tableau <- function(path, ...) {
  read_tsv(path,
           locale    = locale(encoding = "UTF-16LE"),
           col_types = cols(.default = col_character()),
           na        = character(),
           ...)
}

# Writes a UTF-8 CSV with a byte-order mark, so Excel displays the Arabic
# correctly. Fields are quoted only when necessary.
save_csv <- function(data, path) {
  write_excel_csv(data, path, quote = "needed")
}


# ------------------------------------------------------------------------------
# Lookup tables
# ------------------------------------------------------------------------------

# Minor districts: Arabic name in the voter rolls -> English name used in the
# paper, and the major (electoral) district it belongs to under the 2017
# electoral law.
district_names <- tribble(
  ~minor_district_ar,            ~minor_district_en,    ~major_district,
  "بيروت الأولى",                "Beirut I",            "Beirut I",
  "بيروت الثانية",               "Beirut II",           "Beirut II",
  "زحلة",                        "Zahle",               "Bekaa I",
  "قضاءي البقاع الغربي وراشيا",  "West Bekaa-Rashaya",  "Bekaa II",
  "قضاءي بعلبك والهرمل",         "Baalbek-Hermel",      "Bekaa III",
  "جبيل",                        "Jbeil",               "Mount Lebanon I",
  "كسروان",                      "Keserwan",            "Mount Lebanon I",
  "المتن",                       "Metn",                "Mount Lebanon II",
  "بعبدا",                       "Baabda",              "Mount Lebanon III",
  "عاليه",                       "Aley",                "Mount Lebanon IV",
  "الشوف",                       "Chouf",               "Mount Lebanon IV",
  "عكار",                        "Akkar",               "North I",
  "المنية الضنية",               "Minieh-Danniyeh",     "North II",
  "مدينة طرابلس",                "Tripoli city",        "North II",
  "البترون",                     "Batroun",             "North III",
  "بشري",                        "Bcharre",             "North III",
  "الكورة",                      "Koura",               "North III",
  "زغرتا",                       "Zgharta",             "North III",
  "جزين",                        "Jezzine",             "South I",
  "مدينة صيدا",                  "Sidon city",          "South I",
  "صور",                         "Tyre",                "South II",
  "قرى صيدا",                    "Zahrani",             "South II",
  "بنت جبيل",                    "Bint Jbeil",          "South III",
  "قضاءي مرجعيون وحاصبيا",       "Marjeyoun-Hasbaya",   "South III",
  "النبطية",                     "Nabatieh",            "South III"
)

# Governorates: Arabic name in the voter rolls -> English name.
governorate_names <- tribble(
  ~governorate_ar,   ~governorate_en,
  "بيروت",           "Beirut",
  "البقاع",          "Bekaa",
  "بعلبك والهرمل",   "Baalbek-Hermel",
  "جبل لبنان",       "Mount Lebanon",
  "عكار",            "Akkar",
  "الشمال",          "North",
  "الجنوب",          "South",
  "النبطية",         "Nabatieh"
)

# Sect groups used in the paper, built from each voter's personal sect
# ("personalsect" in the voter file). English glosses are in the comments.
sect_groups <- list(
  "Sunni"                = "سني",
  "Shia"                 = c("شيعي",
                             "اسماعيليي"),             # Ismaili
  "Druze"                = "درزي",
  "Alawite"              = "علوي",
  "Maronite"             = "ماروني",
  "Greek Orthodox"       = "روم ارثوذكس",
  "Greek Catholic"       = "روم كاثوليك",
  "Armenian Orthodox"    = "ارمن ارثوذكس",
  "Armenian Catholic"    = "ارمن كاثوليك",
  "Protestant"           = "انجيلي (بروتستانت)",        # Evangelical (Protestant)
  "Christian Minorities" = c("سريان ارثوذكس",           # Syriac Orthodox
                             "سريان كاثوليك",           # Syriac Catholic
                             "لاتيني",                  # Latin
                             "ارمن بروتستانت",          # Armenian Protestant
                             "اشوري",                   # Assyrian
                             "نسطوري",                  # Nestorian
                             "كلدان",                   # Chaldean
                             "كلدان كاثوليك",           # Chaldean Catholic
                             "كلدان ارثوذكس",           # Chaldean Orthodox
                             "قبطي",                    # Coptic
                             "قبطي ارثوذكس",            # Coptic Orthodox
                             "قبطي كاثوليك",            # Coptic Catholic
                             "مسيحي"),                  # Christian, unspecified
  "Other"                = c("اسرائيلي",                # Jewish
                             "لا طائفي",                # no sect
                             "بهائي",                   # Baha'i
                             "بوذي",                    # Buddhist
                             "هندوسي",                  # Hindu
                             "شهود يهوه",               # Jehovah's Witnesses
                             "مختلف",                   # "other"
                             "--", "")                  # not recorded
)
sect_names <- tibble(sect_en      = rep(names(sect_groups), lengths(sect_groups)),
                     personalsect = unlist(sect_groups, use.names = FALSE))


# ------------------------------------------------------------------------------
# Step 1. Individual voter records -> de-identified counts
# ------------------------------------------------------------------------------
from_raw <- file.exists(voter_file)

if (from_raw) {

  # Read only the fields needed; names, dates of birth, etc. are never loaded.
  voters <- read_csv(voter_file,
                     col_select = c(elect_district, governate, sex,
                                    personalsect, simplesect, voting_country),
                     col_types  = cols(.default = col_character()),
                     na         = character())

  voters <- left_join(voters, sect_names, by = "personalsect")

  # The sect groups above must reproduce the voter file's own "simplesect" field.
  stopifnot("sect groups differ from the simplesect field" =
              identical(voters$sect_en, voters$simplesect))

  voter_counts <- voters |>
    transmute(minor_district_ar = elect_district,
              governorate_ar    = governate,
              sect_en,
              sex               = case_when(sex == "الذكور" ~ "male",
                                            sex == "الإناث" ~ "female"),
              voting_country,                        # "" if voting in Lebanon
              registered_abroad = voting_country != "") |>
    count(minor_district_ar, governorate_ar, sect_en, sex,
          voting_country, registered_abroad)

  rm(voters)

} else {
  message("Voter file not found; starting from ", counts_file)
  voter_counts <- read_csv(counts_file,
                           col_types = cols(n                 = col_integer(),
                                            registered_abroad = col_logical(),
                                            .default          = col_character()),
                           na        = character())
}


# ------------------------------------------------------------------------------
# Step 2. Counts -> the analysis datasets
# ------------------------------------------------------------------------------

# (a) One row per minor district
voters_by_district <- voter_counts |>
  group_by(minor_district_ar, governorate_ar) |>
  summarise(registered_total    = sum(n),
            registered_diaspora = sum(n[registered_abroad]),
            male                = sum(n[sex == "male"]),
            female              = sum(n[sex == "female"]),
            .groups = "drop") |>
  mutate(registered_resident = registered_total - registered_diaspora,
         pct_diaspora        = round(100 * registered_diaspora / registered_total, 2),
         pct_female          = round(100 * female / registered_total, 2)) |>
  inner_join(district_names,    by = "minor_district_ar") |>
  inner_join(governorate_names, by = "governorate_ar") |>
  select(major_district, minor_district_en, minor_district_ar,
         governorate_en, governorate_ar,
         registered_total, registered_resident, registered_diaspora, pct_diaspora,
         male, female, pct_female) |>
  arrange(major_district, minor_district_en)

# (b) One row per minor district x sect (sects with no voters in a district are
#     omitted), largest sect first within each district
voters_by_sect <- voter_counts |>
  group_by(minor_district_ar, sect_en) |>
  summarise(registered_total    = sum(n),
            registered_resident = sum(n[!registered_abroad]),
            .groups = "drop") |>
  group_by(minor_district_ar) |>
  mutate(pct_of_district = round(100 * registered_total / sum(registered_total), 3)) |>
  ungroup() |>
  inner_join(district_names, by = "minor_district_ar") |>
  select(major_district, minor_district_en, minor_district_ar, sect_en,
         registered_total, registered_resident, pct_of_district) |>
  arrange(major_district, minor_district_en, desc(registered_total), sect_en)

# (c) Voters registered abroad: one row per country x minor district x sect,
#     largest first
diaspora_by_country <- voter_counts |>
  filter(registered_abroad) |>
  group_by(country_ar = voting_country, minor_district_ar, sect_en) |>
  summarise(registered_diaspora = sum(n), .groups = "drop") |>
  inner_join(district_names, by = "minor_district_ar") |>
  select(country_ar, major_district, minor_district_en, sect_en, registered_diaspora) |>
  arrange(desc(registered_diaspora), country_ar, major_district, minor_district_en, sect_en)


# ------------------------------------------------------------------------------
# Step 3. Check against Tableau's district totals, then save
# ------------------------------------------------------------------------------
# District Pop.csv gives, for each minor district, Tableau's count of all
# registered voters ("Count of Regsect") and of voters registered abroad
# ("Count of Voting Country"). Every district must match exactly.
tableau_totals <- read_tableau(tableau_file) |>
  filter(`admin2Na 11` != "") |>    # drop Tableau's empty "* / Conflict" row
  transmute(minor_district_ar      = `admin2Na 11`,
            tableau_major_district = `Electoral District`,
            tableau_total          = parse_number(`Count of Regsect`),
            tableau_diaspora       = parse_number(`Count of Voting Country`))

mismatches <- voters_by_district |>
  full_join(tableau_totals, by = "minor_district_ar") |>
  filter(is.na(registered_total) | is.na(tableau_total) |
           registered_total    != tableau_total |
           registered_diaspora != tableau_diaspora |
           major_district      != tableau_major_district) |>
  select(minor_district_en, minor_district_ar,
         registered_total, tableau_total, registered_diaspora, tableau_diaspora)

if (nrow(mismatches) > 0) {
  print(mismatches, n = Inf, width = Inf)
  stop("The voter records do not match Tableau's district totals for the ",
       nrow(mismatches), " district(s) listed above, so the voter file is ",
       "incomplete. Nothing was saved.")
}

stopifnot(nrow(voters_by_district) == 25,
          with(voters_by_district, male + female == registered_total))

dir.create(out_dir, showWarnings = FALSE)
if (from_raw) save_csv(voter_counts, counts_file)
save_csv(voters_by_district, file.path(out_dir, "voters_by_electoral_district.csv"))
save_csv(voters_by_sect,     file.path(out_dir, "voters_by_district_sect_long.csv"))
save_csv(diaspora_by_country, file.path(out_dir, "diaspora_voters_by_country_district_sect.csv"))

message("Saved ", nrow(voters_by_district), " district rows, ",
        nrow(voters_by_sect), " district-by-sect rows, and ",
        nrow(diaspora_by_country), " diaspora rows to ", out_dir, "/")
