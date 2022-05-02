-- Median without Aggregates
CREATE OR REPLACE FUNCTION public.median_from_arr(numeric[])
    RETURNS numeric
    LANGUAGE 'sql'
AS $BODY$
   SELECT AVG(val)
   FROM (
     SELECT val
     FROM unnest($1) val
     ORDER BY 1
     LIMIT  2 - MOD(array_upper($1, 1), 2)
     OFFSET CEIL(array_upper($1, 1) / 2.0) - 1
   ) sub;
$BODY$;

SELECT
	CAST(median_from_arr(array_agg(spend)) AS numeric(10,2)) AS median
FROM (
	SELECT
	  spend AS spend
	FROM facebook_ad_data
	WHERE date BETWEEN '2021-07-01' AND '2021-07-31'
	ORDER BY spend
) AS data;

-- Median with Aggregates (also use function median_from_arr)
CREATE OR REPLACE AGGREGATE public.median(numeric) (
    SFUNC = array_append,
    STYPE = numeric[] ,
    FINALFUNC = median_from_arr,
    FINALFUNC_MODIFY = READ_ONLY,
    INITCOND = '{}',
    MFINALFUNC_MODIFY = READ_ONLY
);

SELECT
  CAST(median(spend) AS numeric(10,2)) AS median
FROM facebook_ad_data
WHERE date BETWEEN '2021-07-01' AND '2021-07-31'
ORDER BY median;

-- Mode
SELECT
	spend AS Mode
FROM facebook_ad_data
WHERE date BETWEEN '2021-07-01' AND '2021-07-31'
GROUP BY spend
ORDER BY count(*) desc, spend asc
LIMIT 1;

-- Control sample
SELECT  
	mode() WITHIN GROUP (ORDER BY spend) AS mode,
	percentile_cont(0.5) WITHIN GROUP (ORDER BY spend) AS median
FROM facebook_ad_data
WHERE date between  '2021-07-01' and  '2021-07-31';
