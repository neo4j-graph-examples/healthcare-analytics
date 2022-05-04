Questions - Analytics

//- What are the top 5 side effects reported?

//Top 5 side effects reported
MATCH (c:Case)-[:HAS_REACTION]->(r:Reaction) 
RETURN r.description, count(c) 
ORDER BY count(c) DESC 
LIMIT 5;

//- What are the top 5 drugs reported with side effects? Also fetch the side effects.

//Top 5 drugs reported with side effects, along with their top 5 side effects
MATCH (c:Case)-[:IS_PRIMARY_SUSPECT]->(d:Drug)
MATCH (c)-[:HAS_REACTION]-(r:Reaction)
WITH d.name as drugName, collect(r.description) as sideEffects, count(r.description) as totalSideEffects
RETURN drugName, sideEffects[0..5], totalSideEffects 
ORDER BY totalSideEffects DESC LIMIT 5;


// - What are the manufacturing companies which have most drugs which reported side effects? Company names comes with answer.
//Top 5 manufacturing companies which have most drugs which reported side effects?
MATCH (m:Manufacturer)-[:REGISTERED]->(c)-[:HAS_REACTION]->(r)
WITH m.manufacturerName as company, count(r) as numberOfSideEffects
RETURN company, numberOfSideEffects 
ORDER BY numberOfSideEffects DESC LIMIT 5;


// - What are the top 5 drugs from a particular company with side effects? What are the side effects from those drugs?
//Top 5 drugs from "NOVARTIS" which reported side effects
MATCH (m:Manufacturer {manufacturerName: "NOVARTIS"})-[:REGISTERED]->(c)
MATCH (r:Reaction)<--(c)-[:IS_PRIMARY_SUSPECT]->(d)
WITH d,collect(distinct r.description) AS reactions, count(r) as totalReactions
RETURN DISTINCT(d.name) as drug, reactions[0..5] as sideEffects, totalReactions 
ORDER BY totalReactions DESC
LIMIT 5;

// - What is the age group which reported highest side effects, and what are those side effects?
//Age group which has highest side effects, and what are those side effects?
MATCH (a:AgeGroup)<-[:FALLS_UNDER]-(c:Case)
MATCH (c)-[:HAS_REACTION]->(r)
WITH a, collect(r.description) as sideEffects, count(r) as total
RETURN a.ageGroup as ageGroupName, sideEffects[0..6] as sideEffects 
ORDER BY total DESC
LIMIT 1;

// - What are the highest side effects reported in Children and what are the drugs those caused these side effects?
// Highest side effects reported in Children and what are the drugs those caused these side effects
MATCH (a:AgeGroup {ageGroup:"Child"})<-[:FALLS_UNDER]-(c)
MATCH (c)-[:HAS_REACTION]->(r)
MATCH (c)-[:IS_PRIMARY_SUSPECT]->(d)
WITH distinct r.description as sideEffect, collect(d.name) as drugs, count(r) as sideEffectCount
RETURN sideEffect, drugs 
ORDER BY sideEffectCount desc LIMIT 5;


// - What are the top 10 drugs which are reported directly by consumers for the side efffects?
//Top 10 drugs which are reported directly by consumers for the side efffects
MATCH (c:Case)-[:REPORTED_BY]->(rpsr:ReportSource {name: "Consumer"})
MATCH (c)-[:IS_PRIMARY_SUSPECT]->(d)
MATCH (c)-[:HAS_REACTION]->(r)
WITH rpsr.name as reporter, d.name as drug, collect(r.description) as sideEffects, count(r) as total
RETURN drug, reporter, sideEffects[0..5] as sideEffects 
ORDER BY total desc LIMIT 5;

//- What are the drugs whose side effects resulted in Death of patients as an ouctome?
//Drugs whose side effects resulted in Death of patients as an ouctome
MATCH (c:Case)-[:RESULTED_IN]->(o:Outcome {outcome:"Death"})
MATCH (c)-[:IS_PRIMARY_SUSPECT]->(d)
MATCH (c)-[:HAS_REACTION]->(r)
WITH d.name as drug, collect(r.description) as sideEffects, o.outcome as outcome
RETURN drug, sideEffects[0..5] as sideEffects, outcome 
LIMIT 5;

// - Take one of the case, and list demographics, all the drugs given, side effects and outcome for the patient.
//Take one of the case, and list demographics, all the drugs given, side effects and outcome for the patient
MATCH (c:Case {primaryid: 111791005})
MATCH (c)-[consumed]->(drug:Drug)
MATCH (c)-[:RESULTED_IN]->(outcome)
MATCH (c)-[:HAS_REACTION]->(reaction)
MATCH (therapy)-[prescribed:PRESCRIBED]-(drug)
WITH distinct c.age + ' ' + c.ageUnit as age, c.gender as gender,
collect(distinct reaction.description) as sideEffects,
collect(
    distinct {   drug: drug.name,
        dose: consumed.doseAmount + ' '  + consumed.doseUnit,
        indication: consumed.indication,
        route: consumed.route
    }) as treatment,
collect(distinct outcome.outcome) as outcomes
RETURN age, gender, treatment, sideEffects, outcomes ;
