SELECT * FROM Country_codes;
SELECT * FROM Unemployment_rate
WHERE Year = 2021 AND ;


SELECT A.name AS Name,
	   A.alpha_3 AS Country_Code,
	   A.region AS Region,
	   A.sub_region AS Sub_Region,
	   D.Year AS Year,
	   D.Unemployment_female_of_female_labor_force_modeled_ILO_estimate AS Unemployment_Female,
	   D.Unemployment_male_of_male_labor_force_modeled_ILO_estimate AS Unemployment_Male,
	   B.[2022] + C.[2022] AS Population,
	   B.[2022] AS FemalePop,
	   C.[2022] AS MalePop
FROM Country_codes A
JOIN FemalePop B
ON A.alpha_3 = B.[Country Code]
JOIN MalePop C
ON B.[Country Code] = C.[Country Code]
JOIN Unemployment_rate D
ON A.alpha_3 = D.Code
WHERE Region = 'Africa' AND Year = 2021
ORDER BY Name, Year