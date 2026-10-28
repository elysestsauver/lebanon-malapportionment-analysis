# Lebanon: Proportional Representation Under Consociationalism

Code and data for

> Howard, P. and St Sauver, E. "Lebanon: Proportional Representation Under Consociationalism." Forthcoming submission to a special issue of *Public Choice* on "The Dark Side of Proportional Representation."
>
> Abstract:
> What are the trade-offs of representation associated with guaranteeing political communities fixed shares of a legislature? Constitutions in divided societies routinely allocate a fixed share of the legislature to ethnic, religious, or territorial groups in service of maintaining peaceful power-sharing. We measure how far from proportional representation are apportioned seats in Lebanon, whose 128 parliamentary seats have been divided among fifteen districts and eleven religious confessions by a sequence of political settlements. As the most recent census was conducted in 1932, we use data from the national voter register, the only cur- rent official count of citizens on both dimensions to compute the distribution of the electoral seats under totals proportional to the registered population. About a quarter of the chamber sits with a district or a confession other than the one that an ideal proportional allocation assigns, and reallocating all 128 seats reconciles about half of that difference. The other half is held in place by the equal division of the chamber between Christian and Muslim confessions stipulated by the Taif Agreement. We then test two reforms now under debate, imposing a single national district and variants of a recent provision that allocates seats for citizens from the Lebanese diaspora voting abroad, finding still that the existing 15-district system without the separate diaspora district fares best once seats are reallocated more closely to the proportional ideal.

## Data sources

- **Seat allocation (`seats.csv`)**: statutory allocation of the 128 seats by qada and confession under Law 44/2017, transcribed from the Ministry of Interior and Municipalities' official election publications (2018, 2022). 
- **2022 voter register (`data/population - registered voters/voters_by_district_sect_long.csv`)**: Ministry of Interior and Municipalities, final 2022 voter register (3,967,507 registrants), aggregated to district × sect. Extracted from the `Registered_Voters_by_District.twbx` workbook published by L'Orient Today / L'Orient-Le Jour in its "Mapping Lebanon" series. 
- **2022 diaspora registrants (`data/population - registered voters/diaspora_voters_by_country_district_sect.csv`)**: Registrants abroad by country, district and sect, also from the Ministry of Interior and Municipalities by way of L'Orient Today / L'Orient-Le Jour in its "Mapping Lebanon" series. 


## Authors

Elyse St Sauver and Peyton Howard, Department of Economics, University of California, Irvine. Questions: estsauve[AT]uci.edu, peytoh1[AT]uci.edu

## License

Code: [MIT]. Data: [CC BY 4.0], subject to the terms of the original sources.
