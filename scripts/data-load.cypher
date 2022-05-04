//Schema - add constraints
CREATE CONSTRAINT constraint_drug_name IF NOT EXISTS ON (n: `Drug`) ASSERT n.`name` IS UNIQUE;
CREATE CONSTRAINT constraint_case_primaryid IF NOT EXISTS ON (n: `Case`) ASSERT n.`primaryid` IS UNIQUE;
CREATE CONSTRAINT constraint_reaction_description IF NOT EXISTS ON (n: `Reaction`) ASSERT n.`description` IS UNIQUE;
CREATE CONSTRAINT constraint_reportsource_code IF NOT EXISTS ON (n: `ReportSource`) ASSERT n.`code` IS UNIQUE;
CREATE CONSTRAINT constraint_outcome_code IF NOT EXISTS ON (n: `Outcome`) ASSERT n.`code` IS UNIQUE;
CREATE CONSTRAINT constraint_therapy_primaryid IF NOT EXISTS ON (n: `Therapy`) ASSERT n.`primaryid` IS UNIQUE;
CREATE CONSTRAINT constraint_manufacturer_name IF NOT EXISTS ON (n: `Manufacturer`) ASSERT n.`manufacturerName` IS UNIQUE;
CREATE INDEX index_case_age IF NOT EXISTS FOR (n: `Case`) ON n.`age`;
CREATE INDEX index_case_ageUnit IF NOT EXISTS FOR (n: `Case`) ON n.`ageUnit`;
CREATE INDEX index_case_gender IF NOT EXISTS FOR (n: `Case`) ON n.`gender`;
CREATE INDEX index_case_eventdate IF NOT EXISTS FOR (n: `Case`) ON n.`eventDate`;
CREATE INDEX index_case_reportdate IF NOT EXISTS FOR (n: `Case`) ON n.`reportDate`;

-------------------------------------------------------------------------------------------------------------------------------

//Load cases and manufacturers and relate them
//Also relate cases to occured in countries and reported in countries
//Create Age Group nodes and link them to cases
LOAD CSV WITH HEADERS FROM "https://gist.githubusercontent.com/chintan196/8e11111b45140eed463b8bff9f42846c/raw/f65416dcd1e07392e30b3b680080356510966491/demographics.csv" AS row

//Conditionally create Case nodes, set properties on first create
MERGE (c:Case { primaryid: toInteger(row.primaryid) })
ON CREATE SET
c.eventDate= date(row.eventDate),
c.reportDate= date(row.reportDate),
c.age = toFloat(row.age),
c.ageUnit = row.ageUnit,
c.gender = row.sex,
c.reporterOccupation = row.reporterOccupation

//Conditionally create Manufacturer
MERGE (m:Manufacturer { manufacturerName: row.manufacturerName } )

//Relate case and manufacturer
MERGE (m)-[:REGISTSRED]->(c)

//Conditionally create age group node and relate with case
MERGE (a:AgeGroup { ageGroup: row.ageGroup })

//Relate case with age group
MERGE (c)-[:FALLS_UNDER]->(a)

RETURN count (c);

-------------------------------------------------------------------------------------------------------------------------------

//Load outcomes and link them with cases
LOAD CSV WITH HEADERS FROM "https://gist.githubusercontent.com/chintan196/8a01b48f6fd6ed54e18b1811c3e029f6/raw/74ad44733c11bb006e9e1fa3cdf68fcace3dfc30/outcome.csv" AS row

// Conditionally create outcome node
MERGE (o:Outcome { code: row.code })
ON CREATE SET
o.outcome = row.outcome

WITH o, row

// Find the case to relate this outcome to
MATCH (c:Case {primaryid: toInteger(row.primaryid)})

// Relate
MERGE (c)-[:RESULTED_IN]->(o)

RETURN count(o);

-------------------------------------------------------------------------------------------------------------------------------

//Load reactions and link them with cases
LOAD CSV WITH HEADERS FROM "https://gist.githubusercontent.com/chintan196/e6f36dfb8899f1fb7a631e07cac93ffd/raw/f879244ed0159cb591dc0a31c21455f8fb250b02/reaction.csv" AS row

//Conditionally create reaction node
MERGE (r:Reaction { description: row.description })

WITH r, row

//Find the case to relate this reaction to
MATCH (c:Case {primaryid: toInteger(row.primaryid)})

//Relate
MERGE (c)-[:HAS_REACTION]->(r)

RETURN count(r);

-------------------------------------------------------------------------------------------------------------------------------

//Load report sources and link them with cases
LOAD CSV WITH HEADERS FROM "https://gist.githubusercontent.com/chintan196/0645a2ec35d83dae73b82823d5434f40/raw/f8e0af63bef793e7339d0244bcb54fad229ae112/reportSources.csv" AS row

// Conditionally create reportSource node
MERGE (r:ReportSource { code: row.code })
ON CREATE SET
r.name = row.name

WITH r, row

// Find the case to relate this report source to
MATCH (c:Case {primaryid: toInteger(row.primaryid) })

WITH c, r

// Relate
MERGE (c)-[:REPORTED_BY]->(r)

RETURN count(r);


-------------------------------------------------------------------------------------------------------------------------------

//Load  drugs with indications and link them with cases using relationships based on their roles for the cases
:auto USING PERIODIC COMMIT 5000 LOAD CSV WITH HEADERS FROM "https://gist.githubusercontent.com/chintan196/709116a064c273999fb7a93ecb3ec261/raw/82df5284fff73d01b227c12f5b6df866fd5a80fd/drugs-indication.csv" AS row

//Conditionally create outcome node
MERGE (d:Drug { name: row.name })
ON CREATE SET
d.primarySubstabce = row.primarySubstabce

WITH d, row

//Find the case to relate this outcome to
MATCH (c:Case {primaryid: toInteger(row.primaryid)})

FOREACH (_ IN CASE WHEN row.role = "Primary Suspect" THEN [1] ELSE [] END |
//Relate
MERGE (c)-[relate:IS_PRIMARY_SUSPECT { drugSequence: row.drugSequence, route: row.route, doseAmount: row.doseAmount, doseUnit: row.doseUnit, indication: row.indication  }]->(d)
)

FOREACH (_ IN CASE WHEN row.role = "Secondary Suspect" THEN [1] ELSE [] END |
//Relate
MERGE (c)-[relate:IS_SECONDARY_SUSPECT { drugSequence: row.drugSequence, route: row.route, doseAmount: row.doseAmount, doseUnit: row.doseUnit, indication: row.indication  }]->(d)
)

FOREACH (_ IN CASE WHEN row.role = "Concomitant" THEN [1] ELSE [] END |
//Relate
MERGE (c)-[relate:IS_CONCOMITANT { drugSequence: row.drugSequence, route: row.route, doseAmount: row.doseAmount, doseUnit: row.doseUnit, indication: row.indication  }]->(d)
)

FOREACH (_ IN CASE WHEN row.role = "Interacting" THEN [1] ELSE [] END |
//Relate
MERGE (c)-[relate:IS_INTERACTING { drugSequence: row.drugSequence, route: row.route, doseAmount: row.doseAmount, doseUnit: row.doseUnit, indication: row.indication  }]->(d)
);

-------------------------------------------------------------------------------------------------------------------------------

//Load therapies and link them with cases and drugs
LOAD CSV WITH HEADERS FROM "https://gist.githubusercontent.com/chintan196/ca26bf83c1fe0e54ef4991173daa9cc0/raw/754b6970c235e398ebf35535162a81689e51ba98/therapy.csv" AS row

//Conditionally create therapy node
MERGE (t:Therapy { primaryid: toInteger(row.primaryid) })

WITH t, row

//Find the case to relate this outcome to
MATCH (c:Case {primaryid: toInteger(row.primaryid)})

//Relate case with therapy
MERGE (c)-[:RECEIVED]->(t)

WITH c, t, row

//Find drugs prescribed in the therapy
MATCH (d:Drug { name: row.drugName })

//Relate therapy and drugs
MERGE (t)-[:PRESCRIBED { drugSequence: row.drugSequence, startYear: coalesce(row.startYear, 1900), endYear: coalesce(row.endYear, 2021) } ]->(d);
------------------------------------------------------------------------------------------------------------------------------------

